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
    echo "========== 계정 잠금 임계값 설정 ============"
    if [ -f $file ]; then 
        if sudo grep -qE "^\s*auth\s+required\s+/lib/security/pam_tally.so" "$file"; then 
            value=$(sudo grep "/lib/security/pam_tally.so" "$file" | grep -oP 'deny\s*=\s*\K[0-9]+')
            if [[ "$value" =~ ^[0-9]+$  ]] && [ $value -le 10 ]; then 
                log "INFO" "계정 잠금 임계값 결과 양호"
            else
                log "WARN" "deny설정이 없거나 10회 이상입니다"
            fi 
        else 
            log "WARN" "pam_tally.so모듈을 사용하고 있지 않습니다"
        fi
    else 
        log "WARN" "/etc/pam.d/system-auth 파일을 찾을 수 없습니다"
    fi

}
# auth required /lib/security/pam_tally.so 블라블라 deny=5 라는 패턴이 들어가 있으면 최소 기준은 맞춘거네 


#========== 메인 ============


load_config
U_01
U_02





#==========공부노트 ============
# /etc/pam.d/login에 보면 무슨 모듈을 쓸지 나오는데 밑에 모듈이 있어야 하고 
# auth required /lib/security/pam_securetty.so
# 이 모듈은 etc/securetty를 참조해서 루트가 무슨 터미널로 로그인 가능할지 정의한다. 
# tty는 물리터미널이고 pts는 가상터미널(ssh같은)이기 때문에 루트는 무조건 물리터미널에서만 로그인 가능하게 설정해야 한다. 