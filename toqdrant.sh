#!/bin/bash

set -e

# path to the gaianet base directory
gaianet_base_dir="$HOME/gaianet"

# 配置 GDRANT 地址和端口
GDRANT_HOST="${GDRANT_HOST:-localhost}"
GDRANT_PORT="${GDRANT_PORT:-6333}"

deleteVectorDB() {
    local DBName=$1
    curl -X DELETE "http://${GDRANT_HOST}:${GDRANT_PORT}/collections/${DBName}"
}

checkVectorDB() {
    local DBName=$1
    curl -s "http://${GDRANT_HOST}:${GDRANT_PORT}/collections/${DBName}" | jq '.result.vectors_count'
}

createVectorDB() {
    local DBName=$1
    local size=$2
    local distance=$3

    curl -X PUT "http://${GDRANT_HOST}:${GDRANT_PORT}/collections/${DBName}" \
    -H "Content-Type: application/json" \
    -d "{\"vectors\": {\"size\": ${size}, \"distance\": \"${distance}\", \"on_disk\": true}}"
}

createEmbeddings() {
    local DBName=$1
    local model_name=$2
    local size=$3
    local filepath=$4

    # 复制文件到 gaianet_base_dir
    local filename=$(basename "$filepath")
    cp "$filepath" "$gaianet_base_dir/$filename"
    # 切换到 gaianet_base_dir
    cd $gaianet_base_dir
    # 执行命令
    command="wasmedge --dir .:. --nn-preload default:GGML:AUTO:${model_name} create_embeddings.wasm default ${DBName} ${size} $filename"
    echo $command
    eval $command

    # 删除 gaianet_base_dir 中的文件
    rm "$gaianet_base_dir/$filename"
    cd -
}

text2qdrant() {
    local filepath=$1
    local db_name="${2:-default}"

    deleteVectorDB "$db_name"
    createVectorDB "$db_name" 768 "Cosine"
    createEmbeddings "$db_name" "nomic-embed-text-v1.5.f16.gguf" 768 "$filepath"
}

if [ "$#" -lt 1 ]; then
    echo "Usage: ./text2gdrant.sh filepath"
    exit 1
fi

text2qdrant "$1"