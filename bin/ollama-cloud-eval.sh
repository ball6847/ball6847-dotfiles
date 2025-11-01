#!/bin/bash

# TODO: add emoji before the word latency
TIMEFORMAT='latency: %R s'
RUN_PROMPT="hi there. answer me in one sentence"

# Available models array
models=(
  "ollama/deepseek-v3.1:671b"
  "ollama/gpt-oss:20b"
  "ollama/gpt-oss:120b"
  "ollama/kimi-k2:1t"
  "ollama/qwen3-coder:480b"
  "ollama/glm-4.6"
  "ollama/minimax-m2"
  "zai-coding-plan/glm-4.5-air"
  "zai-coding-plan/glm-4.6"
)

echo "--------------------------------"
echo "Evaluating Ollama Cloud Models"

for model in "${models[@]}"; do
  echo
  echo "Testing $model"
  time opencode run --agent plan -m "$model" "$RUN_PROMPT"
  echo "--------------------------------"
done
