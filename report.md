# 서버 보안 감사 보고서<br>

**작성일:** 25-11-15<br>

**점검 대상:** EC2 Apache 서버 (IP: 192.168.0.1)<br>

**작성자:** ec2-user<br>

 <br>

## 1. 개요<br>

본 보고서는 부서에서 관리하는 리눅스 서버에 대해 보안관리가 제대로 이루어지고 있는지 점검하는 것을 목적으로 한다.<br>

 <br>

### 점검 범위<br>

* 사용자 계정 상태 관리<br>

* 주요 파일 권한 및 소유자 점검 <br>

* 위험 서비스 동작 유무 점검 <br>

* 주요 서비스 환경설정파일 점검 <br>

* 기타 보안 점검 <br>

## 2. 점검 결과 요약<br>


| 구분 | 등급 | 발견건수 | 비율 | 상세 항목 |
| ----- | ----- | ----- | ----- | ----- |
| 점검결과 | 안전  | 25건  | 64.00%   | U_01 U_04 U_05 U_06 U_07 U_08 U_11 U_12 U_14 U_16 U_18 U_20 U_22 U_23 U_24 U_25 U_26 U_27 U_28 U_29 U_30 U_31 U_33 U_35 U_37 |
|   | 경고  | 2건 | 5.00% | U_10 U_17 |
|   | 취약  | 12건 | 31.00% | U_00 U_02 U_03 U_09 U_13 U_15 U_19 U_21 U_32 U_34 U_36 U_38 |
| 총계 | - | 39건 | 100% | - |

## 3. 상세 점검 결과<br>

39가지 보안 점검 사항에 대해 평가기준(양호, 경고, 취약)을 정의하고, 이를 기반으로 수행된 최종 점검 결과를 표시한다<br>

>### U-0 pts로그인 설정 확인<br>

* 점검 기준<br>

  + 시스템 정책에 root 계정의 원격터미널 접속차단 설정이 적용되어 있는지 점검<br>

* 양호<br>

  + tty로만 root로그인이 가능한 경우<br>

* 경고<br>

  +  주요 파일(/etc/pam.d/login /etc/securetty)이 존재하지 않을 경우<br>

* 취약<br>

  +  pty로 루트 로그인이 가능한 상태일 경우<br>

* 점검 결과<br>

  + 취약<br>

 ---
>### U-1 ssh 설정 확인<br>

* 점검 기준<br>

  + 원격 루트 로그인과 원격 비밀번호 로그인 불가능 설정이 적용되어 있는지 점검<br>

* 양호<br>

  +  원격 루트 로그인과 비밀번호를 이용한 로그인이 불가능한 경우<br>

* 경고<br>

  +  ssh 미설치일 경우<br>

* 취약<br>

  +  원격 루트 로그인 혹은 비밀번호 로그인이 가능한 경우<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-2 패스워드 복잡성 설정<br>

* 점검 기준<br>

  + 유저가 패스워드를 설정할때 충분히 복잡하게 작성하도록 제한이 되어있는지 점검<br>

* 양호<br>

  + 소문자/대문자/숫자/특수문자 최소1개+패스워드 길이가 8이상으로 설정된 경우<br>

* 경고<br>

  +  /etc/security/pwquality.conf 설정 파일이 존재하지 않을 경우<br>

* 취약<br>

  +  패스워드 정책이 기준에 미치지 않은 경우<br>

* 점검 결과<br>

  + 취약<br>

 ---
>### U-3 계정 잠금 임계값 설정<br>

* 점검 기준<br>

  +  사용자 계정 로그인 실패시 계정잠금 임계값이 적절하게 설정되어 있는지 점검<br>

* 양호<br>

  + 계정잠금 임계값이 10회 미만으로 설정되어 있는 경우<br>

* 경고<br>

  +  /etc/pam.d/system-auth 설정 파일이 존재하지 않을 경우<br>

* 취약<br>

  +  계정잠금이 임계값이 설정되어 있지 않거나 10회 이상일 경우<br>

* 점검 결과<br>

  + 취약<br>

 ---
>### U-4 패스워드 파일 보호<br>

* 점검 기준<br>

  + 섀도 패스워드가 설정되어 있는지 점검<br>

* 양호<br>

  + 섀도 패스워드가 설정되어 있는 경우<br>

* 경고<br>

  + N/A<br>

* 취약<br>

  + 패스워드가 평문으로 저장되어 있는 경우<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-5 환경변수 경로 점검<br>

* 점검 기준<br>

  + PATH 환경변수에 . 혹은 ::이 포함되어 있는지 점검<br>

* 양호<br>

  + PATH 환경변수에 “.” 이 맨 앞이나 중간에 포함되지 않고 ::가 없는 경우<br>

* 경고<br>

  + N/A<br>

* 취약<br>

  +  "."이 맨 앞이나 중간에 포함되어 있거나 ::가 존재하는 경우<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-6 파일 및 디렉토리 소유자 점검<br>

* 점검 기준<br>

  + 소유자가 존재하지 않는 파일/ 디렉터리가 존재하는지 점검<br>

* 양호<br>

  + /etc/passwd에 등록되지 않은 유저와 그룹 소유의 파일 혹은 디렉토리가 존재하지 않음<br>

* 경고<br>

  + N/A<br>

* 취약<br>

  + /etc/passwd에 등록되지 않은 유저와 그룹 소유의 파일 혹은 디렉토리가 존재함<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-7 /etc/passwd파일 권한 점검<br>

* 점검 기준<br>

  + /etc/passwd 파일의 권한을 점검<br>

* 양호<br>

  +  /etc/passwd 파일 권한이 644 이하이고 소유자가 root인 경우<br>

* 경고<br>

  +  /etc/passwd 파일이 존재하지 않을 경우<br>

* 취약<br>

  +  /etc/passwd 파일 권한이 644 초과이거나 소유자가 root가 아닐 경우<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-8 파일 권한 점검<br>

* 점검 기준<br>

  + /etc/shadow 파일의 권한을 점검<br>

* 양호<br>

  +  /etc/shadow 파일 권한이 400 이하이고 소유자가 root인 경우<br>

* 경고<br>

  +  /etc/shadow 파일이 존재하지 않을 경우<br>

* 취약<br>

  +  /etc/shadow 파일 권한이 400 초과이거나 소유자가 root가 아닐 경우<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-9 /etc/hosts파일 권한 점검<br>

* 점검 기준<br>

  + /etc/hosts 파일의 권한을 점검<br>

* 양호<br>

  +  /etc/hosts 파일 권한이 600 이하이고 소유자가 root인 경우<br>

* 경고<br>

  +  /etc/hosts 파일이 존재하지 않을 경우<br>

* 취약<br>

  +  /etc/hosts 파일 권한이 400 초과이거나 소유자가 root가 아닐 경우<br>

* 점검 결과<br>

  + 취약<br>

 ---
>### U-10 xinetd 관련 파일 권한 점검<br>

* 점검 기준<br>

  + /etc/xinetd.conf” 파일 및 “/etc/xinetd.d/” 하위 모든 파일의 소유자 및 권한을 점검<br>

* 양호<br>

  + 소유자가 root가 아니거나 파일의 권한이 600 이 아닌 파일이 없을 경우<br>

* 경고<br>

  +  /etc/xinetd.conf 파일 혹은 /etc/xinetd.d 디렉토리가 존재하지 않을 경우<br>

* 취약<br>

  +  소유자가 root가 아니거나 파일의 권한이 600 이 아닌 파일이 존재할 경우<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-11 rsyslog.conf 파일 권한 점검<br>

* 점검 기준<br>

  + rsyslog.conf 파일 권한 점검<br>

* 양호<br>

  + "rsyslog.conf” 파일의 소유자가 root이고 파일의 권한이 640이하인 경우<br>

* 경고<br>

  + rsyslog.conf 파일이 존재하지 않을 경우<br>

* 취약<br>

  + rsyslog.conf” 파일의 소유자가 root가 아니거나 파일의 권한이 640초과인 경우<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-12 services 파일 권한 점검<br>

* 점검 기준<br>

  + services 파일 권한 점검<br>

* 양호<br>

  + "/etc/services” 파일의 소유자가 root이고 파일의 권한이 644이하인 경우<br>

* 경고<br>

  + /etc/services 파일이 존재하지 않을 경우<br>

* 취약<br>

  + /etc/services” 파일의 소유자가 root가 아니거나 파일의 권한이 644초과인 경우<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-13 불필요한 SUID SGID 점검<br>

* 점검 기준<br>

  + 중요 파일들중 SUID 혹은 SGID가 설정되있는지 점검<br>

* 양호<br>

  + 중요 파일들에 SUID 혹은 SGID가 설정되어 있지 않은 경우<br>

* 경고<br>

  + N/A<br>

* 취약<br>

  + 중요 파일들에 SUID 혹은 SGID가 설정되어 있는 경우<br>

* 점검 결과<br>

  + 취약<br>

 ---
>### U-14 사용자 환경파일 소유자 및 권한 점검<br>

* 점검 기준<br>

  + 홈 디렉터리 내의 환경변수 파일에 대해 소유자와 권한이 적절히 설정되어 있는지 점검<br>

* 양호<br>

  +  사용자의 홈 디렉터리에 존재하는 환경변수 파일들의 권한이 모두 644 이하이고 소유자가 본인 혹은 root인 경우<br>

* 경고<br>

  +  N/A<br>

* 취약<br>

  +  사용자의 홈 디렉터리에 존재하는 환경변수 파일들중 권한이 644초과 혹은 소유자가 본인 혹은 root이외의 계정인 파일이 1개 이상인 경우<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-15 world writable 파일 점검<br>

* 점검 기준<br>

  + 가상 파일을 제외하고 other에 쓰기권한이 있는 파일인 world writable 파일이 존재하는지 점검<br>

* 양호<br>

  + 가상 파일을 제외하고 world writable 파일이 존재하지 않음<br>

* 경고<br>

  + N/A<br>

* 취약<br>

  + 가상 파일을 제외하고 world writable 파일이 존재함<br>

* 점검 결과<br>

  + 취약<br>

 ---
>### U-16 /dev에 존재하지 않는 device 파일 점검<br>

* 점검 기준<br>

  + /dev에 파일 타입의 데이터가 있는지 확인하고 major minor number를 가지지 않는 device 파일이 존재하는지 점검<br>

* 양호<br>

  +  /dev에 파일 타입의 데이터가 존재하지 않고 major minor number를 가지지 않는 device 파일이 존재하지 않음<br>

* 경고<br>

  + N/A  <br>

* 취약<br>

  + /dev에 파일 타입의 데이터가 존재하거나 major minor number를 가지지 않는 device 파일이 존재함<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-17 접속 IP 및 포트 제한<br>

* 점검 기준<br>

  +  접속을 허용할 호스트 및 포트를 설정해놨는지 점검<br>

* 양호<br>

  + /etc/hosts.allow 파일에 ALL:ALL 설정이 없고 /etc/hosts.deny 파일에 ALL:ALL 설정이 있을 경우<br>

* 경고<br>

  + /etc/hosts.deny 파일이 존재하지 않을 경우<br>

* 취약<br>

  + #/etc/hosts.deny 파일에 ALL:ALL 설정이 없거나 /etc/hosts.allow 파일에 ALL:ALL 설정이 있을 경우<br>

* 점검 결과<br>

  + 경고<br>

 ---
>### U-18 finger서비스 활성화 유무 점검<br>

* 점검 기준<br>

  + 사용하지 않는 finger서비스를 비활성화 했는지 점검<br>

* 양호<br>

  + finger서비스가 비활성화 되어있는 경우<br>

* 경고<br>

  + N/A<br>

* 취약<br>

  +  finger서비스가 활성화 되어있는 경우<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-19 FTP 계정 유무 점검<br>

* 점검 기준<br>

  +  FTP계정이 존재하는지 점검<br>

* 양호<br>

  + /etc/passwd 파일에 ftp계정이 등록되어 있지 않은 경우<br>

* 경고<br>

  + N/A<br>

* 취약<br>

  + /etc/passwd 파일에 ftp계정이 등록되어 있는 경우<br>

* 점검 결과<br>

  + 취약<br>

 ---
>### U-20 r 계열 서비스 비활성화 점검<br>

* 점검 기준<br>

  + 불필요한 r계열 서비스가 비활성화 되어 있는지 점검<br>

* 양호<br>

  + 불필요한 r계열 서비스가 비활성화 되어 있는 경우<br>

* 경고<br>

  + N/A<br>

* 취약<br>

  + 불필요한 r계열 서비스가 활성화 되어 있는 경우<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-21 crond 파일 소유자 및 권한 설정<br>

* 점검 기준<br>

  + cron관련 파일들의 권한 및 소유자를 점검<br>

* 양호<br>

  + 모든 cron관련 파일들의 권한이 640이하이고 소유자가 root일 경우<br>

* 경고<br>

  + N/A<br>

* 취약<br>

  + 권한이 640 초과이거나 소유자가 root가 아닌 cron관련 파일이 존재할 경우<br>

* 점검 결과<br>

  + 취약<br>

 ---
>### U-22 DoS 공격에 취약한 서비스 비활성화<br>

* 점검 기준<br>

  + ntp discard와 같은 Dos공격에 취약한 서비스들을 비활성화 했는지 점검<br>

* 양호<br>

  + Dos공격에 취약한 7개 서비스에 대해 inactive상태일떄<br>

* 경고<br>

  + N/A<br>

* 취약<br>

  +  active상태인 서비스가 1개 이상일때<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-23 NFS 서비스 점검<br>

* 점검 기준<br>

  + 불필요한 NFS 서비스가 동작중인지 점검<br>

* 양호<br>

  + 불필요한 NFS 서비스들이 모두 비활성화 상태일때<br>

* 경고<br>

  + N/A<br>

* 취약<br>

  +  불필요한 NFS 서비스가 실행중일때<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-24 NFS 접근 권한 확인<br>

* 점검 기준<br>

  + NFS 사용시 허가된 사용자만 접근 가능하게 설정했는지 점검<br>

* 양호<br>

  + 접근 권한에 everyone이 포함되어 있지 않은 경우<br>

* 경고<br>

  +  /etc/exports 파일이 존재하지 않을 경우<br>

* 취약<br>

  +  접근 권한에 everyone이 포함되어 있는 경우<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-25 automountd 서비스 점검<br>

* 점검 기준<br>

  + 취약점이 존재하는 automountd 서비스를 비활성화 했는지 점검<br>

* 양호<br>

  +  automount 서비스를 비활성화 한 경우<br>

* 경고<br>

  + N/A <br>

* 취약<br>

  +  automount 서비스가 동작중인 경우<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-26 RPC 서비스 점검<br>

* 점검 기준<br>

  + 불필요한 RPC 서비스가 동작중인지 점검<br>

* 양호<br>

  + 불필요한 RPC 서비스들이 모두 비활성화 상태일때<br>

* 경고<br>

  + N/A<br>

* 취약<br>

  +  불필요한 RPC 서비스가 실행중일때<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-27 NIS NIS+ 점검<br>

* 점검 기준<br>

  + 불필요한 NIS 서비스가 동작중인지 점검<br>

* 양호<br>

  + 불필요한 NIS 서비스들이 모두 비활성화 상태일때<br>

* 경고<br>

  + N/A<br>

* 취약<br>

  +  불필요한 NIS 서비스가 실행중일때<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-28 tftp talk 서비스 점검<br>

* 점검 기준<br>

  + 불필요한 tftp talk 서비스가 동작중인지 점검<br>

* 양호<br>

  + 불필요한 tftp talk 서비스들이 모두 비활성화 상태일때<br>

* 경고<br>

  + N/A<br>

* 취약<br>

  +  불필요한 tftp talk 서비스가 실행중일때<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-29 스팸 메일 릴레이 제한<br>

* 점검 기준<br>

  + SMTP 서버의 릴레이 기능 제한 여부 점검<br>

* 양호<br>

  + sendmail 서비스를 사용중이 아니거나 스팸 메일 릴레이 제한이 설정된 상태인 경우<br>

* 경고<br>

  + /etc/mail/sendmail.cf 파일이 존재하지 않을 경우<br>

* 취약<br>

  + 스팸 메일 릴레이 제한이 설정되있지 않은 경우<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-30 일반사용자의 Sendmail 실행 방지<br>

* 점검 기준<br>

  + SMTP 서비스 사용 시 일반사용자의 q 옵션 제한 여부 점검<br>

* 양호<br>

  + SMTP 서비스 미사용 또는 일반 사용자의 Sendmail 실행 방지가 설정된 경우<br>

* 경고<br>

  + /etc/mail/sendmail.cf 파일이 존재하지 않을 경우<br>

* 취약<br>

  + SMTP 서비스 사용 및 일반 사용자의 Sendmail 실행 방지가 설정되어 있지 않은 경우<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-31 DNS Zone Transfer 점검<br>

* 점검 기준<br>

  + 허가된 사용자에게만 Zone Transfer이 설정되었는지 점검<br>

* 양호<br>

  + DNS 서비스 미사용 또는 Zone Transfer를 허가된 사용자에게만 허용한 경우<br>

* 경고<br>

  + /etc/named.conf 파일이 존재하지 않을 경우<br>

* 취약<br>

  + DNS 서비스를 사용하며 Zone Transfer를 모든 사용자에게 허용한 경우<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-32 웹서비스 디렉토리 리스팅 점검<br>

* 점검 기준<br>

  + 외부에서 웹서버 내의 디렉토리 정보를 볼 수 있는 웹서비스 디렉토리 리스팅 기능이 제한되어 있는지 점검<br>

* 양호<br>

  + 웹서비스 디렉토리 리스팅 기능이 제한된 상태<br>

* 경고<br>

  + /etc/httpd/conf/httpd.conf 파일이 존재하지 않을 경우<br>

* 취약<br>

  +  웹서비스 디렉토리 리스팅이 가능한 상태<br>

* 점검 결과<br>

  + 취약<br>

 ---
>### U-33 웹서비스 웹 프로세스 권한 제한<br>

* 점검 기준<br>

  + Apache 데몬이 root 권한으로 구동되는지 여부 점검<br>

* 양호<br>

  + Apache 데몬이 유저 그룹 모두 root 이외의 권한으로 구동중일 경우<br>

* 경고<br>

  + /etc/httpd/conf/httpd.conf 파일이 존재하지 않을 경우<br>

* 취약<br>

  + Apache 데몬이  root 권한으로 구동중일 경우<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-34 웹서비스 상위 경로 이동 가능 여부 점검<br>

* 점검 기준<br>

  + “..” 와 같은 문자 사용 등으로 상위 경로로 이동이 가능한지 여부 점검<br>

* 양호<br>

  + 상위 디렉터리에 이동제한을 설정한 경우<br>

* 경고<br>

  + /etc/httpd/conf/httpd.conf 파일이 존재하지 않을 경우<br>

* 취약<br>

  + 상위 디렉터리에 이동제한을 설정하지 않은 경우<br>

* 점검 결과<br>

  + 취약<br>

 ---
>### U-35 웹서비스 불필요한 파일 존재 여부 점검<br>

* 점검 기준<br>

  + Apache 설치 시 기본으로 생성되는 불필요한 파일의 삭제 여부 점검<br>

* 양호<br>

  + /usr/share/httpd/htdocs/manual 랑 /usr/share/httpd/manual 두 디렉터리 모두 존재하지 않을 경우<br>

* 경고<br>

  + N/A<br>

* 취약<br>

  +  /usr/share/httpd/htdocs/manual 랑 /usr/share/httpd/manual 두 디렉터리 중 하나라도 존재할 경우<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-36 웹서비스 링크 사용금지 점검<br>

* 점검 기준<br>

  + 심볼릭 링크와 aliases 사용 제한 여부 점검<br>

* 양호<br>

  + 심볼릭 링크와 aliases 사용이 제한된 상태<br>

* 경고<br>

  + /etc/httpd/conf/httpd.conf 파일이 존재하지 않을 경우<br>

* 취약<br>

  + 심볼릭 링크와 aliases 사용이 가능한 상태<br>

* 점검 결과<br>

  + 취약<br>

 ---
>### U-37 웹서비스 파일 업로드 및 다운로드 제한<br>

* 점검 기준<br>

  + 파일 업로드 및 다운로드의 사이즈 제한 여부 점검<br>

* 양호<br>

  + 파일 업로드 및 다운로드를 5M 이하로 제한한 경우<br>

* 경고<br>

  + 파일 업로드 및 다운로드를 5M 초과로 제한했거나 /etc/httpd/conf/httpd.conf 설정파일이 존재하지 않을 경우<br>

* 취약<br>

  + 파일 업로드 및 다운로드를 제한하지 않은 경우<br>

* 점검 결과<br>

  + 양호<br>

 ---
>### U-38 웹서비스 영역의 분리<br>

* 점검 기준<br>

  + 웹 서버의 루트 디렉터리와 OS의 루트 디렉터리를 다르게 지정하였는지 점검<br>

* 양호<br>

  + DocumentRoot를 기본경로가 아닌 별도의 디렉터리로 지정한 경우<br>

* 경고<br>

  + /etc/httpd/conf/httpd.conf 파일이 존재하지 않을 경우<br>

* 취약<br>

  + DocumentRoot를 기본 디렉터리로 지정한 경우<br>

* 점검 결과<br>

  + 취약<br>

 ---
## 4. 취약 항목 요약 및 조치<br>

다음은 점검 결과가 취약인 항목에 대한 현황 보고와 권장 조치 방안입니다.<br>

>## U_00 <br>

* 현황<br>

  + auth required /lib/security/pam_securetty.so 설정이 포함되어 있지 않음.<br>

* 조치<br>

  + /etc/pam.d/login 파일에 auth required /lib/security/pam_securetty.so을 추가<br>



>## U_02 <br>

* 현황<br>

  + 최소 소문자 개수 부족<br>

* 조치<br>

  + /etc/security/pwquality.conf 파일의 lcredit 값을 확인해주세요.<br>


* 현황<br>

  + 최소 대문자 개수 부족<br>

* 조치<br>

  + /etc/security/pwquality.conf 파일의 ucredit 값을 확인해주세요.<br>


* 현황<br>

  + 최소 숫자 개수 부족<br>

* 조치<br>

  + /etc/security/pwquality.conf 파일의 dcredit 값을 확인해주세요.<br>


* 현황<br>

  + 최소 특수문자 개수 부족<br>

* 조치<br>

  + /etc/security/pwquality.conf 파일의 ocredit 값을 확인해주세요.<br>


* 현황<br>

  + 최소 패스워드 길이가 짧습니다.<br>

* 조치<br>

  + /etc/security/pwquality.conf 파일의 minlen 값을 확인해주세요.<br>


>## U_03 <br>

* 현황<br>

  + pam_tally.so모듈을 사용하고 있지 않습니다<br>

* 조치<br>

  + /etc/pam.d/system-auth 파일에 account required /lib/security/pam_tally.so를 추가해주세요<br>



>## U_09 <br>

* 현황<br>

  + /etc/hosts 파일의 권한이 큽니다.<br>

* 조치<br>

  + /etc/hosts 파일의 권한을 600 이하로 설정해주세요. <br>



>## U_13 <br>

* 현황<br>

  + SUID 혹은 SGID가 설정되어 있는 중요 파일이 존재함<br>

* 조치<br>

  + 불필요한 SUID 혹은 SGID을 제거해주세요 명령어: chmod -s <file_name> <br>


#### SUID 혹은 SGID가 설정되어 있는 중요 파일 목록<br>

* /sbin/unix_chkpwd<br>

* /usr/bin/at<br>

* /usr/bin/newgrp<br>


>## U_15 <br>

* 현황<br>

  + world writable 파일이 존재함<br>

* 조치<br>

  + 불필요한 world writable 파일을 제거해주세요<br>



>## U_19 <br>

* 현황<br>

  + FTP 계정이 존재합니다.<br>

* 조치<br>

  + /etc/passwd 파일에 있는 ftp계정을 삭제해주세요<br>



>## U_21 <br>

* 현황<br>

  + 파일의 권한이 크거나 소유자가 root가 아닌 파일 혹은 디렉토리가 존재합니다.<br>

* 조치<br>

  + 파일 혹은 디렉토리의 권한을 640 이하로 설정하거나 소유자를 root로 변경해주세요.<br>


#### 권한 혹은 소유자 확인이 필요한 crond 관련 파일 목록<br>

* /usr/bin/crontab<br>

* /etc/crontab<br>

* /etc/cron.hourly<br>

* /etc/cron.deny<br>


>## U_32 <br>

* 현황<br>

  + 웹서비스 디렉토리 리스팅이 가능한 상태입니다.<br>

* 조치<br>

  + /etc/httpd/conf/httpd.conf 파일의 Options부분의 Indexes 옵션을 주석처리 해주세요.<br>



>## U_34 <br>

* 현황<br>

  + 상위 디렉터리에 이동이 가능한 상태입니다.<br>

* 조치<br>

  + /etc/httpd/conf/httpd.conf 파일의 AllowOverride None 부분을 주석처리 해주세요.<br>



>## U_36 <br>

* 현황<br>

  + 심볼릭 링크와 aliases 사용이 가능한 상태입니다.<br>

* 조치<br>

  + /etc/httpd/conf/httpd.conf 파일의 Options FollowSymLinks을 삭제 또는 -FollowSymLinks 으로 수정해주세요.<br>



>## U_38 <br>

* 현황<br>

  + DocumentRoot가 기본경로로 지정된 상태입니다.<br>

* 조치<br>

  + DocumentRoot를 /usr/local/apache/htdocs, /usr/local/apache2/htdocs, /var/www/html 이외의 경로로 설정해주세요.<br>
