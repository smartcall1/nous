#!/bin/bash

cat << "EOF"

    ██████╗  ██████╗ ███╗   ██╗███████╗███╗   ███╗ ██████╗      ██╗██╗
    ██╔══██╗██╔═══██╗████╗  ██║██╔════╝████╗ ████║██╔═══██╗     ██║██║
    ██║  ██║██║   ██║██╔██╗ ██║█████╗  ██╔████╔██║██║   ██║     ██║██║
    ██║  ██║██║   ██║██║╚██╗██║██╔══╝  ██║╚██╔╝██║██║   ██║██   ██║██║
    ██████╔╝╚██████╔╝██║ ╚████║███████╗██║ ╚═╝ ██║╚██████╔╝╚█████╔╝██║
    ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝     ╚═╝ ╚═════╝  ╚════╝ ╚═╝
    ═══════════════════════════════════════════════════════════════════
              🤖 MADE BY DONEMOJI, https://x.com/d0nemoji 🤖
    ═══════════════════════════════════════════════════════════════════

EOF

# UTF-8 설정 확인 및 설치
check_utf8() {
    if ! locale -a | grep -i "utf-*8" > /dev/null; then
        echo "⚠️ UTF-8이 설치되어 있지 않습니다. 설치를 진행합니다..."
        if [ -f /etc/debian_version ]; then
            # Debian/Ubuntu 계열
            sudo apt-get update
            sudo apt-get install -y locales
            sudo locale-gen en_US.UTF-8
            sudo update-locale LANG=en_US.UTF-8
        elif [ -f /etc/redhat-release ]; then
            # RHEL/CentOS 계열
            sudo dnf install -y langpacks-en glibc-all-langpacks
        else
            echo "❌ 지원하지 않는 운영체제입니다."
            exit 1
        fi
        echo "✅ UTF-8 설치가 완료되었습니다."
    else
        echo "✅ UTF-8이 이미 설치되어 있습니다."
    fi
}

# API 키 관리 디렉토리
API_KEYS_DIR="api_keys"
mkdir -p "$API_KEYS_DIR"

# API 키 관리 함수
manage_api_keys() {
    while true; do
        echo -e "\n🔑 API 키 관리 메뉴:"
        echo "1. API 키 추가"
        echo "2. API 키 목록 보기"
        echo "3. API 키 삭제"
        echo "4. 시작하기"
        echo "5. 종료"
        read -p "선택하세요 (1-5): " choice

        case $choice in
            1)
                read -p "API 키 이름을 입력하세요: " key_name
                read -p "API 키를 입력하세요: " api_key
                echo "$api_key" > "$API_KEYS_DIR/$key_name"
                echo -e "\n✅ API 키가 저장되었습니다."
                ;;
            2)
                echo -e "\n📋 저장된 API 키 목록:"
                ls -1 "$API_KEYS_DIR" | nl
                ;;
            3)
                echo -e "\n📋 삭제할 API 키 선택:"
                ls -1 "$API_KEYS_DIR" | nl
                read -p "삭제할 번호를 입력하세요: " del_num
                key_name=$(ls -1 "$API_KEYS_DIR" | sed -n "${del_num}p")
                if [ -n "$key_name" ]; then
                    rm "$API_KEYS_DIR/$key_name"
                    echo "✅ API 키가 삭제되었습니다."
                else
                    echo "❌ 잘못된 번호입니다."
                fi
                ;;
            4)
                if [ "$(ls -1 "$API_KEYS_DIR" | wc -l)" -eq 0 ]; then
                    echo "❌ 저장된 API 키가 없습니다. 먼저 API 키를 추가해주세요."
                    continue
                fi
                return 0
                ;;
            5)
                exit 0
                ;;
            *)
                echo "❌ 잘못된 선택입니다."
                ;;
        esac
    done
}

# 채팅봇 실행 함수
run_chatbot() {
    local api_key_name=$1
    local api_key=$(cat "$API_KEYS_DIR/$api_key_name")
    local log_file="logs/${api_key_name}.log"
    mkdir -p logs

    while true; do
        while IFS= read -r input || [[ -n "$input" ]]; do
            if [[ -z "$input" ]]; then
                continue
            fi

            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 👤 You: $input" >> "$log_file"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🤖 Chatbot: 생각 중..." >> "$log_file"

            payload=$(jq -n \
                --arg model "Hermes-3-Llama-3.1-70B" \
                --arg prompt "$input" \
                --argjson max_tokens 200 \
                --argjson temperature 0.7 \
                '{
                    model: $model,
                    prompt: $prompt,
                    max_tokens: $max_tokens,
                    temperature: $temperature
                }')

            response=$(curl -s -X POST "https://inference-api.nousresearch.com/v1/completions" \
                -H "Authorization: Bearer $api_key" \
                -H "Content-Type: application/json" \
                -d "$payload")

            error=$(echo "$response" | jq -r '.error // empty')
            if [[ -n "$error" ]]; then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ 오류 발생: $error" >> "$log_file"
                if [[ "$error" == *"unauthorized"* ]]; then
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ API 키가 유효하지 않습니다." >> "$log_file"
                    return 1
                fi
            else
                reply=$(echo "$response" | jq -r '.choices[0].text' | sed 's/^ *//;s/ *$//')
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🤖 Chatbot: $reply" >> "$log_file"
            fi

            echo "----------------------------------------" >> "$log_file"

            delay=$(( RANDOM % (600 - 180 + 1) + 180 ))
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⏳ 다음 질문까지 약 $delay 초 대기합니다..." >> "$log_file"
            sleep $delay
        done < "questions.txt"
    done
}

# 모니터링 함수 (하나만 남기고 나머지는 삭제)
monitor_chatbots() {
    while true; do
        clear
        echo -e "\n📊 채팅봇 모니터링 대시보드"
        echo "----------------------------------------"
        for api_key_name in "$API_KEYS_DIR"/*; do
            if [ -f "$api_key_name" ]; then
                api_key_name=$(basename "$api_key_name")
                log_file="logs/${api_key_name}.log"
                if [ -f "$log_file" ]; then
                    echo -e "\n🤖 채팅봇: $api_key_name"
                    
                    # 마지막 5줄의 로그를 가져옴
                    last_lines=$(tail -n 5 "$log_file" 2>/dev/null)
                    
                    # 상태 확인 (대기 중인지 확인)
                    if echo "$last_lines" | grep -q "다음 질문까지 약"; then
                        status="대기 중"
                    elif ps aux | grep "run_chatbot $api_key_name" | grep -v grep >/dev/null; then
                        status="실행 중"
                    else
                        status="중지됨"
                    fi
                    
                    echo "상태: $status"
                    echo "마지막 활동:"
                    echo "$last_lines" | while IFS= read -r line; do
                        echo "  $line"
                    done
                    echo "----------------------------------------"
                fi
            fi
        done
        echo -e "\n\n1. 새로고침"
        echo "2. 종료"
        read -p "선택하세요 (1-2): " choice
        if [ "$choice" = "2" ]; then
            break
        fi
        sleep 5
    done
}

# 메인 실행 부분
check_utf8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# API 키 관리
manage_api_keys

# 질문 파일 확인
if [[ ! -f "questions.txt" ]]; then
    echo "❌ 질문 파일 'questions.txt' 을(를) 찾을 수 없습니다."
    exit 1
fi

# 각 API 키별로 채팅봇 실행
for api_key_name in "$API_KEYS_DIR"/*; do
    if [ -f "$api_key_name" ]; then
        api_key_name=$(basename "$api_key_name")
        run_chatbot "$api_key_name" &
    fi
done

# 모니터링 시작 (여기서 바로 모니터링 함수 호출)
monitor_chatbots

# 종료 시 모든 프로세스 정리
pkill -f "run_chatbot"
