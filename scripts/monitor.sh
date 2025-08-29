#!/bin/bash
# monitor.sh - 서버 리소스 모니터링 및 알림
# cpu/mem/disk사용량 확인하고 임계치 이상이면 알람 보내는 스크립트 



#========== 설정 ============
SCRIPT_DIR=$(cd "$(dirname $0)/../" && pwd )
CONFIG_FILE="$SCRIPT_DIR"/config/slack.conf
TIMESTAMP=$(date "+%y%m%d_%H%M%S")
LOG_FILE=$SCRIPT_DIR/reports/monitor_$TIMESTAMP.log



CPU_THRESHOLD=10
MEM_THRESHOLD=15
DISK_THRESHOLD=10

#========== 함수 ============

# 설정 파일에서 변수 불러오는 함수 
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


monitor_server(){
    CPU=$(top -bn 1 | grep "%Cpu" | awk '{print int($2+$4)}')
    if [ $CPU -gt $CPU_THRESHOLD ]; then 
        log "[WARN]" "Cpu 사용량이 높습니다."
        send_alert "서버 Cpu 사용량이 높습니다. 확인 부탁드립니다."
    fi 

    MEM=$(free | awk '/Mem:/ {printf( "%d",$3/$2*100)}')
    if [ $MEM -gt $MEM_THRESHOLD ]; then 
        log "[WARN]" "Memory 사용량이 높습니다." 
        send_alert "서버 메모리 사용량이 높습니다. 확인 부탁드립니다."
  
    fi 

    DISK=$(df -h / | awk ' NR==2 {gsub(/%/,"",$5); print $5}') 
    if [ $DISK -gt $DISK_THRESHOLD ]; then 
        log "[WARN]" "Disk 사용량이 높습니다." 
        send_alert "서버 디스크 사용량이 높습니다. 확인 부탁드립니다."

    fi 
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


#========== 메인 ============


monitor_server

