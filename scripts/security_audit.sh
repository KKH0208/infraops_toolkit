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
    if grep -qE "^[[:space:]]*passwordAuthentication[[:space:]]+yes" /etc/ssh/sshd_conf; then 
        log "WARN" "passwordAuthentication yes 발견"
        ((ssh_warn +=1))
    fi 

    if grep -qE "^[[:space:]]*PermitRootLogin[[:space:]]+yes" /etc/ssh/sshd_conf; then 
        log "WARN" "PermitRootLogin yes 발견"
        ((ssh_warn +=1))
    fi  

    if [ $only_tty_root_login -eq 1 ] && [ $ssh_warn -eq 0 ]; then 
        log "INFO" "U_01테스트 결과 안전"
    else
        log "WARN" "U_02테스트 결과 취약"
    fi



        
}



#========== 메인 ============


load_config
U_01





#==========공부노트 ============
# /etc/pam.d/login에 보면 무슨 모듈을 쓸지 나오는데 밑에 모듈이 있어야 하고 
# auth required /lib/security/pam_securetty.so
# 이 모듈은 etc/securetty를 참조해서 루트가 무슨 터미널로 로그인 가능할지 정의한다. 
# tty는 물리터미널이고 pts는 가상터미널(ssh같은)이기 때문에 루트는 무조건 물리터미널에서만 로그인 가능하게 설정해야 한다. 