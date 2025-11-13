


#2,10,13,14,22 23 24 27 28 29 38 이 놈들은 error_code_list값 순회하고 1이면 Json에서 가져와서 반복해서 출력해야할듯 case로 저 번호일땐 순회해서 1이면 출력 이런 느낌으로 create_vuln_action_plan 고치자 





#/bin/bash 

#========== 설정 ============

SCRIPT_DIR=$(cd "$(dirname $0)" && pwd )
TIMESTAMP=$(date "+%y%m%d_%H%M%S")
report="report_${TIMESTAMP}.md"
source ./security_audit.sh
csv_file="../config/data_for_report.csv"
json_file="../config/error_code_table.json"

#========== 함수 ============

write_md(){
    echo "$1  " >> $report
}


create_header() {
    write_md "# 서버 보안 감사 보고서"
    write_md "***"
    write_md "**작성일:** $(date '+%y-%m-%d')"
    write_md "**점검 대상:** EC2 Apache 서버 (IP: 192.168.0.1)"
    write_md "**작성자:** ${USER}"
    write_md " "
}

create_audit_purpose() {
    write_md "## 1. 서버 보안 감사 목적"
    write_md "본 부서에서 관리하는 50대의 리눅스 서버에 대해 보안관리가 제대로 이루어지고 있는지 점검하는 것을 목적으로 한다."
    write_md " "
}


# 건수 저장하는 변수랑 상세 항목 저장하는 배열 필요함 
create_audit_result_summary() {
    write_md "## 2. 점검 결과 요약"
    write_md ""
    write_md "| 점검 결과 | 건수 | 상세 항목 |"
    write_md "|-----------|------|-----------|"
    write_md "| 안전      | ${pass_cnt}건  | ${passed_items[*]} |"
    write_md "| 경고      | ${fail_cnt}건  | ${failed_items[*]} |"
    write_md "| 취약      | ${na_cnt}건  | ${na_items[*]}      |"
    write_md " "
}

create_audit_result_detail(){
    write_md "## 3. 상세 점검 결과"
    while IFS=',' read -r no title check_criteria pass fail na
    do 
        write_md "### U-$no $title"
        write_md "점검 기준 : $check_criteria"
        write_md "양호 : $pass"
        write_md "경고 : $na"
        write_md "취약 : $fail"
        write_md "점검 결과 : ${audit_result[$no]}"
        write_md " "

    done < "$csv_file"


}

create_vuln_action_plan(){
    write_md "## 4. 취약 항목 요약 및 조치"

    for key in "${!error_code_dict[@]}"; do
        echo "$key → ${error_code_dict[$key]}"
    done

    
    for idx in "${!failed_items[@]}";do
        item=${failed_items[$idx]}
        item=$(echo "$item" | xargs) # 양끝 공백 있으면 제거 
        item=$(echo "$item" | tr -d '\r') #줄바꿈 문자 있으면 제거 

        write_md "## $item "

        

        case $item in 
            U_02|U_10|U_23|U_24|U_29|U_38)
                write_md "특수경우 실행!"
                error_code_len=$(echo "${error_code_dict[$item]}" | wc -w)
                write_md $error_code_len
                subkeys=(${error_code_dict[$item]}) #문자열이니까 일단 배열로 만들어주고 쓰자.
                for ((i=0;i<error_code_len;i++)); do 
                    # write_md "$item  $subkeys[$i]"
                    desc=$(jq -r --arg k "$item" --arg sk "${subkeys[$i]}" '.[$k][$sk].desc' "$json_file")
                    action=$(jq -r --arg k "$item" --arg sk "${subkeys[$i]}" '.[$k][$sk].action // ""' "$json_file")
                    write_md "- 상황: $desc"
                    write_md "- 조치: $action"
                    write_md " "

                done 
                ;;

            *)
                write_md "일반경우 실행!"
                subkey=${error_code_list[$idx]}
                desc=$(jq -r --arg k "$item" --arg sk "$subkey" '.[$k][$sk].desc' "$json_file")
                action=$(jq -r --arg k "$item" --arg sk "$subkey" '.[$k][$sk].action // ""' "$json_file")
                write_md "- 상황: $desc"
                write_md "- 조치: $action"
                write_md " "

                if [ "$item" == "U_13" || "$item" == "U_14" || "$item" == "U_21" || "$item" == "U_22" || "$item" == "U_26" || "$item" == "U_27" || "$item" == "U_28" || "$item" == "U_35" ]; then 
                    if [ "$item" == "U_13" ]; then 
                        write_md "SUID 혹은 SGID가 설정되어 있는 중요 파일 목록"            
                    elif [ "$item" == "U_14" ]; then 
                        write_md "권한 혹은 소유자 확인이 필요한 사용자 환경파일 목록"
                    elif [ "$item" == "U_21" ]; then 
                        write_md "권한 혹은 소유자 확인이 필요한 crond 관련 파일 목록"
                    elif [ "$item" == "U_22" ]; then 
                        write_md "실행중인 DoS 공격에 취약한 서비스 목록"     
                    elif [ "$item" == "U_26" ]; then 
                        write_md "실행중인 RPC 관련 서비스 목록"
                    elif [ "$item" == "U_27" ]; then 
                        write_md "실행중인 NIS, NIS+ 관련 서비스 목록"
                    elif [ "$item" == "U_28" ]; then 
                        write_md "실행중인 tftp, talk 관련 서비스 목록"
                    elif [ "$item" == "U_35" ]; then 
                        write_md "웹서비스 불필요한 파일 목록"
                    fi 

                    # 연관 배열에서 값을 가져와서, 공백을 기준으로 배열로 분리
                    local files_to_print=(${warning_files[U_13]}) 

                    for file in "${files_to_print[@]}"; do 
                        write_md "$file"
                    done 
                fi

13 14 21 22 26 27 28 35






                write_md " "
                ;;
        esac

    done 

}





#========== 메인 ============


touch $report
create_header
create_audit_purpose
create_audit_result_summary
create_audit_result_detail
create_vuln_action_plan

cat $report




# 지금 해결해야 하는것 
# 1. 경고항목은 4출력 하는데 취약항목은 출력 안하는듯 
# 2. 취약 항목도 출력이 이상함. 일반이상은 괜찮은데 특수경우가 출력 이상한듯 