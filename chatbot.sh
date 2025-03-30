#!/bin/bash

cat << "EOF"

     🤖 Welcome to Donemoji Chatbot 🤖
---------------------------------------------
EOF

# UTF-8 설정
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# API 설정
API_KEY="<YOUR_API_KEY>"
API_URL="https://inference-api.nousresearch.com/v1/completions"
MODEL_NAME="Hermes-3-Llama-3.1-70B"

# 질문 파일 경로
QUESTION_FILE="questions.txt"

if [[ ! -f "$QUESTION_FILE" ]]; then
    echo "❌ 질문 파일 '$QUESTION_FILE' 을(를) 찾을 수 없습니다."
    exit 1
fi

echo "🔁 질문 반복 시작 (Ctrl+C로 종료)"

# 무한 루프
while true; do
    while IFS= read -r input || [[ -n "$input" ]]; do
        if [[ -z "$input" ]]; then
            continue
        fi

        echo "👤 You: $input"
        echo "🤖 Chatbot: 생각 중..."

        payload=$(jq -n \
            --arg model "$MODEL_NAME" \
            --arg prompt "$input" \
            --argjson max_tokens 200 \
            --argjson temperature 0.7 \
            '{
                model: $model,
                prompt: $prompt,
                max_tokens: $max_tokens,
                temperature: $temperature
            }')

        response=$(curl -s -X POST "$API_URL" \
            -H "Authorization: Bearer $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$payload")

        error=$(echo "$response" | jq -r '.error // empty')
        if [[ -n "$error" ]]; then
            echo "❌ 오류 발생: $error"
        else
            reply=$(echo "$response" | jq -r '.choices[0].text' | sed 's/^ *//;s/ *$//')
            echo "🤖 Chatbot: $reply"
        fi

        echo "----------------------------------------"
        sleep 1
    done < "$QUESTION_FILE"
done
