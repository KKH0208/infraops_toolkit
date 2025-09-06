#!/bin/bash 

#========== 설정 ============

SCRIPT_DIR=$(cd "$(dirname $0)/../" && pwd )
CONFIG_FILE="$SCRIPT_DIR"/config/slack.conf
TIMESTAMP=$(date "+%y%m%d_%H%M%S")
LOG_FILE=$SCRIPT_DIR/reports/audit_$TIMESTAMP.log


#========== 함수 ============

load_config(){
    if [ -f "$CONFIG_FILE" ]; then 
        source "$CONFIG_FILE"
    else
        echo "[ERROR] config file not found : "$CONFIG_FILE" "
        exit 1 
    fi 
}

log(){
    local level=$1
    local mesg=$2
    LOG_TIMESTAMP=$(date "+%y%m%d_%H%M%S")

    echo "$mesg" 
    echo "[$LOG_TIMESTAMP][$level] $mesg" >> $LOG_FILE 
}


send_alert(){
    MSG=$1
    if [ -z $WEBHOOK_URL ]; then 
        log "[WARN]" "WEBHOOK_URL 환경변수를 설정해주세요"
        return 1
    fi

    curl -s -X POST --data-urlencode "payload={\"channel\": \"$CHANNEL_NAME\", \"username\": \"$USERNAME\", \"text\": \"$MSG\", \"icon_emoji\": \":ghost:\"}" $WEBHOOK_URL >/dev/null
    if [ $? -ne 0 ]; then 
        log "[ERROR]" "slack 알람 전송에 실패했습니다"
        return 1
    fi
}

audit_server(){
    ssh_warn=0
    log "INFO" "서버 보안 점검을 시작합니다"

}

check_password_quality(){
    local key=$1 
    local min=$2
    local value=$(grep -E "^[[:space:]]*$1[[:space:]]*=" "$file" | awk -F'=' '{gsub(/ /,"",$2); print $2}')

    if grep -qE "^[[:space:]]*$1[[:space:]]*=" "$file" ; then 
            if [ -n $value ] && [ $value -ge $min ]; then 
                log "INFO" "$key 설정 통과"
                ((password_test+=1))
            else
                log "WARN" "$key 설정 부족"
        fi 
    else 
        log "WARN" "${key}이 설정되지 않았습니다"
    fi 

}


U_01(){
    local only_tty_root_login=0
    local ssh_warn=0

    echo "========== pts로그인 설정 확인 ============"

    if [ -f /etc/pam.d/login ]; then 
        if grep -E "^\s*auth\s+required\s+/lib/security/pam_securetty.so" /etc/pam.d/login; then 
            if [ -f /etc/securetty ]; then 
                if grep "pty" /etc/securetty; then 
                    log "WARN" "pty로 루트 로그인이 가능한 상태입니다."
                else 
                    log "INFO" "tty로만 root로그인이 가능합니다"
                    ((only_tty_root_login+=1))
                fi
            else    
                log "WARN" "/etc/securetty파일이 존재하지 않습니다"
            fi 
        else
            log "WARN" "auth required /lib/security/pam_securetty.so이 포함되어 있지 않습니다."
        fi
    else 
        log "WARN" "/etc/pam.d/login 파일이 없습니다"
    fi 

    echo "========== ssh 설정 확인 ============"
    if [ -f /etc/ssh/sshd_config ]; then 
        if sudo grep -qE "^[[:space:]]*passwordAuthentication[[:space:]]+yes" /etc/ssh/sshd_config; then 
            log "WARN" "passwordAuthentication yes 발견"
            ((ssh_warn +=1))
        else
            log "INFO" "원격 비밀번호 로그인 불가능 설정 확인"
        fi 

        if sudo grep -qE "^[[:space:]]*PermitRootLogin[[:space:]]+yes" /etc/ssh/sshd_config; then 
            log "WARN" "PermitRootLogin yes 발견"
            ((ssh_warn +=1))
        else
            log "INFO" "원격 루트 로그인 불가능 설정 확인"
        fi  
    else
        log "WARN" "ssh설정파일이 없습니다. ssh 설치 여부를 확인해주세요"
        ((ssh_warn +=1))
    fi 


    if [ $only_tty_root_login -eq 1 ] && [ $ssh_warn -eq 0 ]; then 
        log "INFO" "U_01테스트 결과 안전"
    else
        log "WARN" "U_01테스트 결과 취약"
    fi
    
}



password_test=0

U_02(){
    echo "========== 패스워드 복잡성 설정 ============"
    local lcredit=1 #소문자 최소 1자 이상 요구
    local ucredit=1 #최소 대문자 1자 이상 요구
    local dcredit=1 #최소 숫자 1자 이상 요구
    local ocredit=1 #최소 특수문자 1자 이상 요구
    local minlen=8  #최소 패스워드 길이 8자 이상 
    local file="/etc/security/pwquality.conf"

    if [ -f "$file" ]; then 
        check_password_quality "lcredit" "$lcredit"
        check_password_quality "ucredit" "$ucredit"
        check_password_quality "dcredit" "$dcredit"
        check_password_quality "ocredit" "$ocredit"
        check_password_quality "minlen" "$minlen"
    else 
        log "WARN" "pwquality.conf 파일이 없습니다."
    fi

    if [ $password_test -eq 5 ]; then 
        log "INFO" "U_02테스트 결과 안전"
    else
        log "WARN" "U_02테스트 결과 취약"
    fi        
}

U_03(){
    #계정 잠금 임계값이 10회 이하의 값으로 설정되어 있으면 통과
    file="/etc/pam.d/system-auth"
    U_03_result=0
    echo "========== 계정 잠금 임계값 설정 ============"
    if [ -f $file ]; then 
        if sudo grep -qE "^\s*auth\s+required\s+/lib/security/pam_tally.so" "$file"; then 
            value=$(sudo grep "/lib/security/pam_tally.so" "$file" | grep -oP 'deny\s*=\s*\K[0-9]+')
            if [[ "$value" =~ ^[0-9]+$  ]] && [ $value -le 10 ]; then 
                log "INFO" "계정 잠금 임계값 결과 양호"
                $U_03_result=1
            else
                log "WARN" "deny설정이 없거나 10회 이상입니다"
            fi 
        else 
            log "WARN" "pam_tally.so모듈을 사용하고 있지 않습니다"
        fi
    else 
        log "WARN" "/etc/pam.d/system-auth 파일을 찾을 수 없습니다"
    fi

    if [ $U_03_result -eq 1 ]; then 
        log "INFO" "U_03테스트 결과 안전"
    else
        log "WARN" "U_03테스트 결과 취약"
    fi  

}

U_04(){
    echo "========== 패스워드 파일 보호 ============"
    if [ $(awk -F':' '$2 != "x"' /etc/passwd | wc -l) -gt 0 ]; then 
        log "WARN" "섀도 패스워드가 설정되어 있지 않습니다"
        log "WARN" "U_04테스트 결과 취약"

    else
        log "INFO" "U_04테스트 결과 안전"
    fi 
}

U_05(){
    #PATH 환경변수에 “.” 이 맨 앞이나 중간에 포함되지 않은 경우 + ::가 없는 경우 
    echo "========== 환경변수 경로 점검 ============"
    warning=$(echo $PATH | grep -E "\.:|::" | wc -l )
    if [ $warning -gt 0 ]; then 
        log "WARN" "환경변수 경로에 '.:' 혹은 '::'이 포함되어 있습니다"
        log "WARN" "U_05테스트 결과 취약"

    else
        log "INRO" "환경변수 경로 검사 결과 양호"
        log "INFO" "U_05테스트 결과 안전"
    fi 
}

U_06(){
    # 소유자가 존재하지 않는 파일/ 디렉터리가 존재하는지 
    echo "========== 파일 및 디렉토리 소유자 점검 ============"
    echo "점검중..."
    nouser_file_num=$(sudo find / -nouser -quit -print 2>/dev/null  | wc -l)
    nogroup_file_num=$(sudo find / -nogroup -quit -print 2>/dev/null | wc -l)

    if [ $nouser_file_num -gt 0 ] && [ $nogroup_file_num -gt 0 ]; then 
        log "WARN" "/etc/passwd에 등록되지 않은 유저와 그룹 소유의 파일 혹은 디렉토리가 존재합니다"
        log "WARN" "U_06테스트 결과 취약"

    elif [ $nouser_file_num -gt 0 ]; then 
        log "WARN" "/etc/passwd에 등록되지 않은 유저 소유의 파일 혹은 디렉토리가 존재합니다"
        log "WARN" "U_06테스트 결과 취약"
    
    elif  [ $nogroup_file_num -gt 0 ]; then 
        log "WARN" "/etc/passwd에 등록되지 않은 그룹 소유의 파일 혹은 디렉토리가 존재합니다"
        log "WARN" "U_06테스트 결과 취약"
    else
        log "INRO" "파일 및 디렉토리 소유자 점검 결과 양호"
        log "INFO" "U_06테스트 결과 안전"
    fi 

}   

U_07(){
    echo "========== /etc/passwd파일 권한 점검 ============"

    if [ -f /etc/passwd ]; then 

        check=$(find /etc/passwd -type f -perm /0133 | wc -l)
        if [ $check -eq 1 ]; then 
            log "WARN" "/etc/passwd파일의 권한이 큽니다"
            log "WARN" "U_07테스트 결과 취약" 
        else
            user=$(ls -l /etc/passwd | awk '{print $3}')
            group=$(ls -l /etc/passwd | awk '{print $4}')

            if [ $user = "root" ] && [ $group = "root" ]; then 
                log "INFO" "U_07테스트 결과 안전"
            else
                log "WARN" "/etc/passwd파일의 소유자가 root가 아닙니다"
                log "WARN" "U_07테스트 결과 취약"           
            fi

        fi

    else 
        log "WARN" "/etc/passwd파일이 존재하지 않습니다"
        log "WARN" "U_07테스트 결과 취약"
    fi

}

U_08(){
    echo "========== /etc/shadow파일 권한 점검 ============"
    if [ -f /etc/shadow ]; then 

        check_000=$(find /etc/shadow -type f -perm 000 | wc -l )
        check_400=$(find /etc/shadow -type f -perm 400 | wc -l )

        if [ $check_000 -eq 0 ] && [ $check_400 -eq 0 ]; then 
            log "WARN" "/etc/passwd파일의 권한이 큽니다"
            log "WARN" "U_08테스트 결과 취약" 

        else
            user=$(ls -l /etc/shadow | awk '{print $3}')
            group=$(ls -l /etc/shadow | awk '{print $4}')

            if [ $user = "root" ] && [ $group = "root" ]; then 
                log "INFO" "U_08테스트 결과 안전"
            else
                log "WARN" "/etc/shadow파일의 소유자가 root가 아닙니다"
                log "WARN" "U_08테스트 결과 취약"           
            fi 

            

        fi
    else 
        log "WARN" "/etc/shadow파일이 존재하지 않습니다"
        log "WARN" "U_08테스트 결과 취약"
    fi

}

U_09(){
    echo "========== /etc/hosts파일 권한 점검 ============"
    if [ -f /etc/hosts ]; then 
        check=$(find /etc/hosts -type f -perm /0177 | wc -l)
        if [ $check -eq 1 ]; then 
            log "WARN" "/etc/hosts 파일의 권한이 큽니다"
            log "WARN" "U_09테스트 결과 취약" 
        else
            user=$(ls -l /etc/hosts | awk '{print $3}')
            group=$(ls -l /etc/hosts | awk '{print $4}')

            if [ $user = "root" ] && [ $group = "root" ]; then 
                log "INFO" "U_09테스트 결과 안전"
            else
                log "WARN" "/etc/hosts파일의 소유자가 root가 아닙니다"
                log "WARN" "U_09테스트 결과 취약"           
            fi

        fi

    else 
        log "WARN" "/etc/hosts파일이 존재하지 않습니다"
        log "WARN" "U_09테스트 결과 취약"
    fi   
}

#일단은 inetd는 옛날이니까 xinetd만 확인하자 
U_10(){
    # “/etc/xinetd.conf” 파일 및 “/etc/xinetd.d/” 하위 모든 파일의 소유자 및 권한 확인
    #ls –l /etc/xinetd.conf
    #ls –al /etc/xinetd.d/*
    #소유자가 root가 아니거나 파일의 권한이 600 이 아닌 경우
    
    echo "========== xinetd 관련 파일 권한 점검 ============"
    
    xinetd_conf=0 # 만약 검사 통과하면 1됨 
    xinetd_d=1    # 얘는 디렉토리이기 때문에 일단 1로 해놓고 만약 하나라도 이상하면 0으로 바꾸고 break하는 식

    if [ -f /etc/xinetd.conf ]; then 
        check=$(find /etc/xinetd.conf -type f -perm 600 | wc -l)
        if [ $check -eq 1 ]; then 
            user=$(ls -l /etc/xinetd.conf | awk '{print $3}')
            group=$(ls -l /etc/xinetd.conf | awk '{print $4}')
            if [ "$user" = "root" ] && [ "$group" = "root" ]; then 
                log "INFO" "/etc/xinetd.conf 검사 결과 양호"
                ((xinetd_conf+=1))
            else
                log "WARN" "/etc/xinetd.conf 파일의 소유자가 root가 아닙니다"
            fi 
        else 
            log "WARN" "/etc/xinetd.conf 파일의 권한이 너무 큽니다"
        fi 

    else 
        log "WARN" "/etc/xinetd.conf파일이 존재하지 않습니다"
    fi 

    if [ -d /etc/xinetd.d ]; then 
        for file in /etc/xinetd.d/*; do 
            [ -f "$file" ] || continue
            check=$(find "$file" -type f -perm 600 | wc -l)
            if [ $check -ne 1 ]; then 
                log "WARN" "${file}의 파일 권한이 너무 큽니다"
                ((xinetd_d-=1))
                break
            else
                user=$(ls -l "$file" | awk '{print $3}')
                group=$(ls -l "$file" | awk '{print $4}')
                if [ $user != "root" ] || [ $group != "root" ]; then 
                    log "WARN" "/etc/xinetd.conf 파일의 소유자가 root가 아닙니다"
                    ((xinetd_d-=1))
                    break

                fi 
            fi 
        done 
        

    else 
        log "WARN" "/etc/xinetd.d 디렉토리가 존재하지 않습니다"
    fi 

    if [ $xinetd_conf -eq 1 ] && [ $xinetd_d -eq 0 ]; then 
        log "INFO" "U_10테스트 결과 안전"
    else
        log "WARN" "U_10테스트 결과 취약"
    fi 
}

U_11(){
    echo "========== rsyslog.conf 파일 권한 점검 ============"
    #“syslog.conf” 파일의 소유자가 root가 아니거나 파일의 권한이 640이하인 경우 아래의 보안설정방법에 따라 설정을 변경함
    
    if [ -f /etc/rsyslog.conf ]; then 
        check=$(find /etc/rsyslog.conf -type f -perm /0137 | wc -l)
        if [ $check -eq 1 ]; then 
            log "WARN" "/etc/rsyslog.conf 파일의 권한이 큽니다"
            log "WARN" "U_11테스트 결과 취약"
        else 
            user=$(ls -l /etc/rsyslog.conf | awk '{print $3}')
            group=$(ls -l /etc/rsyslog.conf | awk '{print $4}')
            if [ $user != "root" ] || [ $group != "root" ]; then 
                log "WARN" "/etc/rsyslog.conf 파일의 소유자가 root가 아닙니다"
                log "WARN" "U_11테스트 결과 취약"
            else 
                log "INFO" "U_11테스트 결과 안전"
            fi 
        fi 

            

    else 
        log "WARN" "/etc/rsyslog.conf 파일이 존재하지 않습니다"
    fi 
}

U_12(){
    echo "========== services 파일 권한 점검 ============"
    #/etc/services 파일의 소유자가 root가 아니거나 파일의 권한이 644 이하인 경우 아래의 보안설정방법에 따라 설정을 변경함
    
    if [ -f /etc/services ]; then 
        check=$(find /etc/services -type f -perm /0133 | wc -l)
        if [ $check -eq 1 ]; then 
            log "WARN" "/etc/services 파일의 권한이 큽니다"
            log "WARN" "U_12테스트 결과 취약"
        else 
            user=$(ls -l /etc/services | awk '{print $3}')
            group=$(ls -l /etc/services | awk '{print $4}')
            if [ $user != "root" ] || [ $group != "root" ]; then 
                log "WARN" "/etc/services 파일의 소유자가 root가 아닙니다"
                log "WARN" "U_12테스트 결과 취약"
            else 
                log "INFO" "U_12테스트 결과 안전"
            fi 
        fi 

            

    else 
        log "WARN" "/etc/services 파일이 존재하지 않습니다"
    fi 
}

U_13(){
    echo "========== 불필요한 SUID,SGID 점검 ============"

    
    check_files=(
    "/sbin/dump"
    "/sbin/restore"
    "/sbin/unix_chkpwd"
    "/usr/bin/at"
    "/usr/bin/lpq"
    "/usr/bin/lpq-lpd"
    "/usr/bin/lpr"
    "/usr/bin/lpr-lpd"
    "/usr/bin/lprm"
    "/usr/bin/lprm-lpd"
    "/usr/bin/newgrp"
    "/usr/sbin/lpc"
    "/usr/sbin/lpc-lpd"
    "/usr/sbin/traceroute"
    )

    #SUID,SGID가 포함되어 있는 파일 목록을 저장 
    warning_files=()

    for file in "${check_files[@]}"; do 
        if [ ! -f $file ]; then 
            log "WARN" "$file 파일이 존재하지 않습니다."
        else 
            if ls -alL $file | awk '{print $1}' | grep -Eq '[sS]|[gG]'; then 
                warning_files+=("$file") 
            fi 
        fi 

    done 

    if [ ${#warning_files[@]} -gt 0 ]; then 
        for file in "${warning_files[@]}"; do 
            echo "SUID 혹은 SGID가 설정된 파일: $file"
        done 
        
        log "WARN" "U_13테스트 결과 취약"
    else 
        log "INFO" "U_13테스트 결과 안전"
    fi 






}

#========== 메인 ============


load_config
U_01
U_02
U_03
U_04
U_05
#U_06 오래 걸려서 일단 주석처리
U_07
U_08
U_09
U_10
U_11
U_12
U_13



#==========공부노트 ============
# /etc/pam.d/login에 보면 무슨 모듈을 쓸지 나오는데 밑에 모듈이 있어야 하고 
# auth required /lib/security/pam_securetty.so
# 이 모듈은 etc/securetty를 참조해서 루트가 무슨 터미널로 로그인 가능할지 정의한다. 
# tty는 물리터미널이고 pts는 가상터미널(ssh같은)이기 때문에 루트는 무조건 물리터미널에서만 로그인 가능하게 설정해야 한다. 

#find /etc -type f -perm /0133 | wc -l 
#여기서 -perm /0133 이거는 --x-wx-wx 이 5개중 하나라도 들어있으면 1이고 하나도 안들어있으면 0
# xx-x-----
# --x-xxxxx 1 3 7 