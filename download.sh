#!/usr/bin/env bash

# Copyright (c) Meta Platforms, Inc. and affiliates.
# This software may be used and distributed according to the terms of the Llama 2 Community License Agreement.

set -e

read -p "Enter the URL from email: " https://download.llamameta.net/*?Policy=eyJTdGF0ZW1lbnQiOlt7InVuaXF1ZV9oYXNoIjoiYnBnMHk3MTNqMXN2M2x3ZGU4ZGR0bGo5IiwiUmVzb3VyY2UiOiJodHRwczpcL1wvZG93bmxvYWQubGxhbWFtZXRhLm5ldFwvKiIsIkNvbmRpdGlvbiI6eyJEYXRlTGVzc1RoYW4iOnsiQVdTOkVwb2NoVGltZSI6MTcxNTkxOTg2MX19fV19&Signature=E23c0shPpTgPBUSEgGYMmKrT4ftPxiwB%7ErBCeiFXULx1z7g8wuR4%7EFPQxOP785QMBgKSJp27ns5qMmItrJuz7hCT0AMqFhDFyX6wet-Nw7xZ3MqCgGNS0i1UESNerdf4I6PyoHJqyFR53gTQ568Kc6gXanNc%7EDvFDlqY7p5Ozyln6dJSYjNcjdrBvYQCOXsReq-Werz5AWq0JDjpZchH6IEBNNoXX3%7E6nB5a4FZdkYpFvwYVZFsFE%7EsJsgMKOINW8xY2aYXJ6IS-fuU6Ywg5n%7EbI7Gh6JF7yrBapq%7EvIdP90xYEG0QLE0kWWxN47GEGQoVQztRh-iT6%7ExUWvrGKxNQ__&Key-Pair-Id=K15QRJLYKIFSLZ&Download-Request-ID=982192763301405echo ""
read -p "Enter the list of models to download without spaces (7B,13B,70B,7B-chat,13B-chat,70B-chat), or press Enter for all: " MODEL_SIZE
TARGET_FOLDER="."             # where all files should end up
mkdir -p ${TARGET_FOLDER}

if [[ $MODEL_SIZE == "" ]]; then
    MODEL_SIZE="7B,13B,70B,7B-chat,13B-chat,70B-chat"
fi

echo "Downloading LICENSE and Acceptable Usage Policy"
wget --continue ${PRESIGNED_URL/'*'/"LICENSE"} -O ${TARGET_FOLDER}"/LICENSE"
wget --continue ${PRESIGNED_URL/'*'/"USE_POLICY.md"} -O ${TARGET_FOLDER}"/USE_POLICY.md"

echo "Downloading tokenizer"
wget --continue ${PRESIGNED_URL/'*'/"tokenizer.model"} -O ${TARGET_FOLDER}"/tokenizer.model"
wget --continue ${PRESIGNED_URL/'*'/"tokenizer_checklist.chk"} -O ${TARGET_FOLDER}"/tokenizer_checklist.chk"
CPU_ARCH=$(uname -m)
  if [ "$CPU_ARCH" = "arm64" ]; then
    (cd ${TARGET_FOLDER} && md5 tokenizer_checklist.chk)
  else
    (cd ${TARGET_FOLDER} && md5sum -c tokenizer_checklist.chk)
  fi

for m in ${MODEL_SIZE//,/ }
do
    if [[ $m == "7B" ]]; then
        SHARD=0
        MODEL_PATH="llama-2-7b"
    elif [[ $m == "7B-chat" ]]; then
        SHARD=0
        MODEL_PATH="llama-2-7b-chat"
    elif [[ $m == "13B" ]]; then
        SHARD=1
        MODEL_PATH="llama-2-13b"
    elif [[ $m == "13B-chat" ]]; then
        SHARD=1
        MODEL_PATH="llama-2-13b-chat"
    elif [[ $m == "70B" ]]; then
        SHARD=7
        MODEL_PATH="llama-2-70b"
    elif [[ $m == "70B-chat" ]]; then
        SHARD=7
        MODEL_PATH="llama-2-70b-chat"
    fi

    echo "Downloading ${MODEL_PATH}"
    mkdir -p ${TARGET_FOLDER}"/${MODEL_PATH}"

    for s in $(seq -f "0%g" 0 ${SHARD})
    do
        wget --continue ${PRESIGNED_URL/'*'/"${MODEL_PATH}/consolidated.${s}.pth"} -O ${TARGET_FOLDER}"/${MODEL_PATH}/consolidated.${s}.pth"
    done

    wget --continue ${PRESIGNED_URL/'*'/"${MODEL_PATH}/params.json"} -O ${TARGET_FOLDER}"/${MODEL_PATH}/params.json"
    wget --continue ${PRESIGNED_URL/'*'/"${MODEL_PATH}/checklist.chk"} -O ${TARGET_FOLDER}"/${MODEL_PATH}/checklist.chk"
    echo "Checking checksums"
    if [ "$CPU_ARCH" = "arm64" ]; then
      (cd ${TARGET_FOLDER}"/${MODEL_PATH}" && md5 checklist.chk)
    else
      (cd ${TARGET_FOLDER}"/${MODEL_PATH}" && md5sum -c checklist.chk)
    fi
done
