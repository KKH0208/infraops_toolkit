#/bin/bash 

#========== 설정 ============

SCRIPT_DIR=$(cd "$(dirname $0)" && pwd )
TIMESTAMP=$(date "+%y%m%d_%H%M%S")
report="report_${TIMESTAMP}.md"
source ./security_audit.sh
csv_file="../config/data_for_report.csv"


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
}

create_audit_purpose() {
    write_md "## 1. 서버 보안 감사 목적"
    write_md "본 부서에서 관리하는 50대의 리눅스 서버에 대해 보안관리가 제대로 이루어지고 있는지 점검하는 것을 목적으로 한다."
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


}





#========== 메인 ============


touch $report
create_header
create_audit_purpose
create_audit_result_summary
create_audit_result_detail
create_vuln_action_plan

cat $report


