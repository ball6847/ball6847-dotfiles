#!/bin/bash

curl -s https://ollama.com/v1/models -H "Authorization: Bearer $OLLAMA_API_KEY" | jq .
