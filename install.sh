#!/bin/bash

set -e

# target name
target=$(uname -m)

# path to the gaianet base directory
gaianet_base_dir="$HOME/gaianet"

check_curl() {
    curl --retry 3 --progress-bar -L "$1" -o "$2"

    if [ $? -ne 0 ]; then
        echo "    * Failed to download $1" >&2
        exit 1
    fi
}

# Download files
check_curl https://github.com/YuanTony/chemistry-assistant/raw/main/rag-embeddings/create_embeddings.wasm $gaianet_base_dir/create_embeddings.wasm 
check_curl https://github.com/0xP0/toqdrant/releases/latest/download/toqdrant.sh $gaianet_base_dir/bin/toqdrant

# Make toqdrant executable
chmod +x $gaianet_base_dir/bin/toqdrant

echo "toqdrant has been downloaded and made executable."
echo "You can now run 'toqdrant' from the command line."