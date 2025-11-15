


#2,10,13,14,22 23 24 27 28 29 38 이 놈들은 error_code_list값 순회하고 1이면 Json에서 가져와서 반복해서 출력해야할듯 case로 저 번호일땐 순회해서 1이면 출력 이런 느낌으로 create_vuln_action_plan 고치자 


#아니 2 10 35가 에러코드 여러개일 수 있는놈이고 13 14 21 22 26 27 28 35가 파일혹은 서비스 종류를 제시해야 하는 놈인데 지금 문제가 35때문이네


#/bin/bash 

#========== 설정 ============

SCRIPT_DIR=$(cd "$(dirname $0)" && pwd )
TIMESTAMP=$(date "+%y%m%d_%H%M%S")
report="report_${TIMESTAMP}.md"
source ./security_audit.sh
csv_file="../config/data_for_report.csv"
json_file="../config/error_code_table.json"
pass_ratio=$(echo "scale=2; ($pass_cnt / 39 ) * 100" | bc)
na_ratio=$(echo "scale=2; ($na_cnt / 39 ) * 100" | bc)
fail_ratio=$(echo "scale=2; 100 - $pass_ratio - $na_ratio" | bc)

#========== 함수 ============

write_md(){
    echo "$1<br>" >> $report
    echo "  " >> $report
}






create_header() {

    cat << EOF > "$report"
---
title: "서버 보안 감사 보고서"
author: "**작성자:** ${USER}"
subtitle: "점검 대상: EC2 Apache 서버 (IP: 192.168.0.1)"
date: "**작성일:** $(date +%y-%m-%d)"
fontsize: 14pt
---

\\newpage
EOF
}
    # echo '---' >>$report
    # echo 'title: "서버 보안 감사 보고서"' >>$report
    # echo 'author: "**작성자:** ${USER}"' >>$report
    # echo 'subtitle: "점검 대상: EC2 Apache 서버 (IP: 192.168.0.1)"' >>$report
    # echo 'date: "**작성일:** $(date '+%y-%m-%d')"' >>$report
    # echo 'fontsize: 14pt ' >>$report
    # echo '---' >>$report
    # echo '\newpage' >>$report



    # write_md "# 서버 보안 감사 보고서"
    # write_md "**작성일:** $(date '+%y-%m-%d')"
    # write_md "**점검 대상:** EC2 Apache 서버 (IP: 192.168.0.1)"
    # write_md "**작성자:** ${USER}"
    # write_md " "
    # echo "\newpage" >>$report
    # echo "---" >>$report






create_audit_purpose() {
    write_md "# 1. 개요"
    write_md "본 보고서는 부서에서 관리하는 리눅스 서버에 대해 보안관리가 제대로 이루어지고 있는지 점검하는 것을 목적으로 한다."
    write_md " "
    write_md "## 점검 범위"
    write_md "* 사용자 계정 상태 관리"
    write_md "* 주요 파일 권한 및 소유자 점검 "
    write_md "* 위험 서비스 동작 유무 점검 "
    write_md "* 주요 서비스 환경설정파일 점검 "
    write_md "* 기타 보안 점검 "

}



# 건수 저장하는 변수랑 상세 항목 저장하는 배열 필요함 
create_audit_result_summary() {
# 탭 들여쓰기를 무시하도록 <<- EOF2 사용
    cat <<- EOF2 >> "$report" 
\begin{center}
\begin{tabular}{|p{1.5cm}|p{1cm}|p{2cm}|p{1.5cm}|p{8cm}|} 
\hline
\textbf{구분} & \textbf{등급} & \textbf{발견건수} & \textbf{비율} & \textbf{상세 항목} \\
\hline
점검결과 & 안전 & 25건 & 64.00\% & U\_01, U\_04, U\_05, U\_06, U\_07, U\_08, U\_11, U\_12, U\_14, U\_16, U\_18, U\_20, U\_22, U\_23, U\_24, U\_25, U\_26, U\_27, U\_28, U\_29, U\_30, U\_31, U\_33, U\_35, U\_37 \\
\hline
& 경고 & 2건 & 5.00\% & U\_10, U\_17 \\
\hline
& 취약 & 12건 & 31.00\% & U\_00, U\_02, U\_03, U\_09, U\_13, U\_15, U\_19, U\_21, U\_32, U\_34, U\_36, U\_38 \\
\hline
\textbf{총계} & & 39건 & 100\% & - \\
\hline
\end{tabular}
\end{center}
EOF2
}


    # write_md "# 2. 점검 결과 요약"
    # echo " " >>$report
    # echo "| 구분 | 등급 | 발견건수 | 비율 | 상세 항목 |" >> $report
    # echo "| ----- | ----- | ----- | ----- | ----- |" >> $report
    # echo "| 점검결과 | 안전  | ${pass_cnt}건  | ${pass_ratio}%   | ${passed_items[*]} |" >> $report
    # echo "|   | 경고  | ${na_cnt}건 | ${na_ratio}% | ${na_items[*]} |" >> $report
    # echo "|   | 취약  | ${fail_cnt}건 | ${fail_ratio}% | ${failed_items[*]} |" >> $report
    # echo "| 총계 | - | 39건 | 100% | - |" >> $report
    # echo " " >>$report



create_audit_result_detail(){
    write_md "# 3. 상세 점검 결과"
    write_md "39가지 보안 점검 사항에 대해 평가기준(양호, 경고, 취약)을 정의하고, 이를 기반으로 수행된 최종 점검 결과를 표시한다"
    while IFS=',' read -r no title check_criteria pass fail na
    do 
        write_md ">## U-$no $title"
        write_md "* 점검 기준"
        write_md "  + $check_criteria"
        write_md "* 양호"
        write_md "  + $pass"
        write_md "* 경고"
        write_md "  + $na"
        write_md "* 취약"
        write_md "  + $fail"
        write_md "* 점검 결과"
        write_md "  + ${audit_result[$no]}"
        echo " --- " >> $report
        echo " " >> $report
        

    done < "$csv_file"


}

create_vuln_action_plan(){
    write_md "# 4. 취약 항목 요약 및 조치"
    write_md "다음은 점검 결과가 취약인 항목에 대한 현황 보고와 권장 조치 방안입니다."

    for idx in "${!failed_items[@]}";do
        item=${failed_items[$idx]}
        item=$(echo "$item" | xargs) # 양끝 공백 있으면 제거 
        item=$(echo "$item" | tr -d '\r') #줄바꿈 문자 있으면 제거 

        write_md ">## $item "

        

        case $item in 
            U_02|U_10|U_35|U_38)
                error_code_len=$(echo "${error_code_dict[$item]}" | wc -w)
                subkeys=(${error_code_dict[$item]}) #문자열이니까 일단 배열로 만들어주고 쓰자.
                for ((i=0;i<error_code_len;i++)); do 
                    # write_md "$item  $subkeys[$i]"
                    desc=$(jq -r --arg k "$item" --arg sk "${subkeys[$i]}" '.[$k][$sk].desc' "$json_file")
                    action=$(jq -r --arg k "$item" --arg sk "${subkeys[$i]}" '.[$k][$sk].action // ""' "$json_file")
                    write_md "* 현황"
                    write_md "  + $desc"
                    write_md "* 조치"
                    write_md "  + $action"
                    echo " " >>$report


                done 
                ;;

            *)
                subkey=${error_code_list[$idx]}
                desc=$(jq -r --arg k "$item" --arg sk "$subkey" '.[$k][$sk].desc' "$json_file")
                action=$(jq -r --arg k "$item" --arg sk "$subkey" '.[$k][$sk].action // ""' "$json_file")
                write_md "* 현황"
                write_md "  + $desc"
                write_md "* 조치"
                write_md "  + $action"
                echo " " >>$report

                if [[ "$item" == "U_13" || "$item" == "U_14" || "$item" == "U_21" || "$item" == "U_22" || "$item" == "U_23" || "$item" == "U_26" || "$item" == "U_27" || "$item" == "U_28" || "$item" == "U_35" ]]; then 
                    if [ "$item" == "U_13" ]; then 
                        write_md "#### SUID 혹은 SGID가 설정되어 있는 중요 파일 목록"  
                        local files_to_print=(${warning_files[U_13]})          
                    elif [ "$item" == "U_14" ]; then 
                        write_md "#### 권한 혹은 소유자 확인이 필요한 사용자 환경파일 목록"
                        local files_to_print=(${warning_files[U_14]})
                    elif [ "$item" == "U_21" ]; then 
                        write_md "#### 권한 혹은 소유자 확인이 필요한 crond 관련 파일 목록"
                        local files_to_print=(${warning_files[U_21]})
                    elif [ "$item" == "U_22" ]; then 
                        write_md "#### 실행중인 DoS 공격에 취약한 서비스 목록"     
                        local files_to_print=(${warning_files[U_22]})
                    elif [ "$item" == "U_23" ]; then 
                        write_md "#### 실행중인 NFS 관련 서비스 목록"     
                        local files_to_print=(${warning_files[U_23]})                        
                    elif [ "$item" == "U_26" ]; then 
                        write_md "#### 실행중인 RPC 관련 서비스 목록"
                        local files_to_print=(${warning_files[U_26]})
                    elif [ "$item" == "U_27" ]; then 
                        write_md "#### 실행중인 NIS, NIS+ 관련 서비스 목록"
                        local files_to_print=(${warning_files[U_27]})
                    elif [ "$item" == "U_28" ]; then 
                        write_md "#### 실행중인 tftp, talk 관련 서비스 목록"
                        local files_to_print=(${warning_files[U_28]})
                    elif [ "$item" == "U_35" ]; then 
                        write_md "#### 웹서비스 불필요한 파일 목록"
                        local files_to_print=(${warning_files[U_35]})
                    fi 




                    for file in "${files_to_print[@]}"; do 
                        write_md "* $file"
                    done 
                fi

                echo " " >>$report

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
pandoc $report -o report_${TIMESTAMP}.pdf --pdf-engine=xelatex -V mainfont="NanumGothic" -V boldfont="NanumGothic" -V geometry:margin=1in -V fontsize=12pt



# 지금 해결해야 하는것 
# 1. 경고항목은 4출력 하는데 취약항목은 출력 안하는듯 
# 2. 취약 항목도 출력이 이상함. 일반이상은 괜찮은데 특수경우가 출력 이상한듯 