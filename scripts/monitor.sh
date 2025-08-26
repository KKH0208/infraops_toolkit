#!/bin/bash
# monitor.sh - 서버 리소스 모니터링 및 알림
# cpu/mem/disk사용량 확인하고 임계치 이상이면 알람 보내는 스크립트 



#========== 설정 ============
SCRIPT_DIR=$(cd "$(dirname $0)/../" && pwd )
TIMESTAMP=$(date "+%y%m%d_%H%M%S")
LOG_FILE=$SCRIPT_DIR/reports/monitor_$TIMESTAMP.log


CPU_THRESHOLD=10
MEM_THRESHOLD=15
DISK_THRESHOLD=10

#========== 함수 ============

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
    fi 

    MEM=$(free | awk '/Mem:/ {printf( "%d",$3/$2*100)}')
    if [ $MEM -gt $MEM_THRESHOLD ]; then 
        log "[WARN]" "Memory 사용량이 높습니다." 
    fi 

    DISK=$(df -h / | awk ' NR==2 {gsub(/%/,"",$5); print $5}') 
    if [ $DISK -gt $DISK_THRESHOLD ]; then 
        log "[WARN]" "Disk 사용량이 높습니다." 
    fi 
}

#========== 메인 ============


monitor_server
