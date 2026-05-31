#!/bin/bash

# Update all Token Plan model endpoints in settings.json
SETTINGS_FILE="$HOME/.qwen/settings.json"
OLD_URL="https://token-plan.cn-beijing.maas.aliyuncs.com/compatible-mode/v1"
NEW_URL="https://token-plan.ap-southeast-1.maas.aliyuncs.com/compatible-mode/v1"

sed -i '' "s|${OLD_URL}|${NEW_URL}|g" "$SETTINGS_FILE"

echo "Updated all model endpoints in $SETTINGS_FILE"
