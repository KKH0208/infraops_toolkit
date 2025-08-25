my_func() {
    local mesg2="반환할 값"

    # 메시지1: 화면에만 출력 (stderr로)
    echo "화면용 메시지1" >&2

    # mesg2: stdout으로 출력 → $()로 변수에 저장 가능
    echo "$mesg2"
}

# 호출
result=$(my_func)
echo "변수에 저장된 값: $result"