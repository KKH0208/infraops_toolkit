#!/bin/bash 

#========== 설정 =============

SCRIPT_DIR=$(cd "$(dirname $0)" && pwd )
CONFIG_FILE="$SCRIPT_DIR"/../config/backup.conf
TIMESTAMP=$(date "+%y%m%d_%H%M%S")
BACKUP_DIR="$SCRIPT_DIR"/../reports/backup
LOG_FILE=$BACKUP_DIR/backup.$TIMESTAMP.log

#========== 함수 =============

# 설정 파일에서 변수 불러오는 함수 
load_config(){
    if [ -f "$CONFIG_FILE" ]; then 
        source "$CONFIG_FILE"
    else
        echo "config file not found : "$CONFIG_FILE" "
        exit 1 
    fi 
}

#첫번째 인수로 받은 디렉토리를 백업폴더로 백업하는 함수 
backup_directory(){
    local target_dir=$1
    local output_file=""$BACKUP_DIR"/dir_"$TIMESTAMP".tar.gz"
    echo "$target_dir >>>>>>>> $output_file 으로 백업 중...." | tee -a $LOG_FILE >&2
    tar -czf "$output_file" "$target_dir"
    echo ""$output_file" 백업이 완료되었습니다" >&2
    echo "$output_file"
    
}

backup_mysql(){
    local db_name=$1
    local output_file="$BACKUP_DIR"/mysql_${db_name}_${TIMESTAMP}.sql.gz 
    echo "$db_name >>>> $output_file 으로 백업 중...." | tee -a $LOG_FILE >&2
    mysqldump -u $MYSQL_USER -p"$MYSQL_PASS" ${db_name} | gzip > $output_file
    echo "$output_file"
}

# 로컬 뿐 아니라 scp를 통해서 다른 백업서버에도 보관하기 
upload_scp(){
    local file=$1
    echo "SCP 업로드: $file >>>>>>> $SCP_USER@$SCP_HOST:$SCP_DIR" | tee -a $LOG_FILE >&2
    scp -P $SCP_PORT "$file"  "$SCP_USER@$SCP_HOST:$SCP_DIR"
    echo 
}

#scp백업 간에 데이터가 손실됬는지 확인 
verify_checksum(){
    local file=$1
    local local_checksum=$(sha256sum "$file" | awk '{print $1}')
    local remote_checksum=$(ssh -P $SCP_PORT "$SCP_USER@$SCP_HOST" "sha256sum '${SCP_DIR}/$(basename "$file")' | awk '{print \$1}'")
    if [ "$local_checksum" = "$remote_checksum" ]; then 
        echo "파일 무결성 체크 완료. 이상 무" | tee -a $LOG_FILE
    else
        echo "파일 무결성 이상 발생. 손실 확인" | tee -a $LOG_FILE >&2
    fi 
}  



#========== 메인실행 =============

load_config
mkdir -p $BACKUP_DIR
while :; do 
    echo "========================"
    echo "InfraOps Toolkit 메인 메뉴"
    echo "1) 디렉토리 백업 "
    echo "2) Mysql 백업 "
    echo "3) 로그 확인 "
    echo "0) 프로그램 종료"
    echo "========================"

    read -p "작업을 선택해주세요 : " choice 
    case "$choice" in
        1) 
            read -p "백업할 디렉토리 경로를 입력해주세요 : " dir 
            if [ ! -d "$dir" ]; then 
                echo "디렉토리를 입력해주세요"
                continue
            fi 

            file=$(backup_directory "$dir")
            echo "===================================="
            echo "$file"
            echo "===================================="

            read -p "백업서버에도 scp로 저장할까요?(y/n) " ans
            if [[ ${ans} =~ ^[Yy]$ ]] ; then

                   upload_scp "$file"
                   verify_checksum "$file"
            else 
                echo "디렉토리 백업이 완료되었습니다. "
            fi 
            ;;
        2) 
            read -p "백업할 데이터베이스를 입력해주세요 : " db
            DB_EXIST=$(mysql -u "$MYSQL_USER" -p"$MYSQL_PASS" -e "SHOW DATABASES LIKE '$db';" -s --skip-column-names)
            if [ -z $DB_EXIST ]; then 
                echo "존재하지 않는 데이터베이스입니다"
                continue
            fi

            file=$(backup_mysql "$db") 
            read -p "백업서버에도 scp로 저장할까요?(y/n) " ans
            if [[ ${ans} =~ ^[Yy]$ ]] ; then 

                   upload_scp "$file"
                   verify_checksum "$file"

            fi
            echo "백업이 완료되었습니다. "
            ;;
        3) 
            echo "=====최근 로그를 출력합니다====="
            tail -n 30 $(ls -t "$BACKUP_DIR"/backup.*.log | head -n 1)
            echo "==========================="
            ;;
        
        0) 
            echo "프로그램을 종료합니다."
            exit 0 
        ;;


    esac


done

#========== 공부용 노트 =============
# 기본적으로 셸 스크립트의 함수는 리턴값을 지정하지 못한다. 그래서 echo내용 모두가 리턴이 된다. 따라서 내가 반환하고 싶지 않은 
# echo내용은 >&2로 표준 에러로 처리해야 한다. 딱히 에러메세지는 아니지만 중요한건 함수리턴값과 단순 표준출력의 분리이기 때문에 이 방법을 쓰자

#sha256sum "$file" 하면 파일 고유의 해시값이 나오기 때문에 좀만 내용이 달라져도 해시값이 완전히 달라짐 

# tee 는 화면에도 출력하고 파일에도 저장하는 두개의 기능을 동시 실행 

#local remote_checksum=$(ssh "$SCP_USER@$SCP_HOST" " sha256sum '${SCP_DIR}/$(basename "$file")' | awk '{print \$1}' ")
#ssh "접속경로" "실행할 명령어" 이 구조인데 "" 안에 ""가 또 들어가면 안되기 때문에 ''로 써줘야 한다. 참고로 $()안에 ""넣는건 서브셸이니까 괜찮음. 
#그리고 ssh접속 후에 SCP_DIR,$file 이렇게 명령 실행해도 이건 우리 로컬에 있는 변수라서 안먹힘. 
#따라서 로컬 셸에서 미리 변수를 해결하고 가야한다. 그래서 $()안에다가 서브셸로 미리 계산하고 ssh보내는거임 
# 반대로 {print \$1} 이부분은 $1이 로컬이 아니라 원격에서 실행되야 하기 때문에 지금 실행 안되게 하려고 
#이스케이프 처리를 해준것임. 

