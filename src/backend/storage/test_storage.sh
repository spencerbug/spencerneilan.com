#!/bin/bash

filename=testfile.txt

fileext=$(echo ${filename} | cut -d'.' -f2)

echo "testfile" > $filename


storage_id=$(dfx canister id storage)

filesize=$(wc -c $filename | sed -e 's/^[[:space:]]*//' | cut -d' ' -f1)

max_payload_size=1900000

num_chunks=$(( filesize/max_payload_size + 1 ))

result=$(dfx canister call ${storage_id} putFileInfo "(record {name=\"$filename\"; createdAt=$(date +%s); size=$filesize; chunkCount=$num_chunks; extension=variant {txt}})")

fileId=$(echo ${result} | cut -d'"' -f2)

# great! Now let's upload our chunk(s)

chunk=$(dd if=$filename ibs=$max_payload_size skip=$(( $max_payload_size * (1 - 1) )) count=$max_payload_size )
result=$(dfx canister call ${storage_id} putFileChunk "(\"$fileId\", 1, blob \"$chunk\")")
bucketId=$(echo ${result} | cut -d'"' -f2)

# for i in $(seq $num_chunks) do
#     chunk=$(dd if=$filename ibs=$max_payload_size skip=$(( $max_payload_size * ($i - 1) )) count=$max_payload_size )
#     dfx canister call ${storage_id} putFileChunk "(\"$fileId\", $i, blob \"$chunk\")"
# done

# let's try to download our chunk with a canister call
dfx canister call ${storage_id} getFileChunk "(\"${fileId}\", 1, principal \"${bucketId}\")"

# lets now try to download our chunk with  an http call

# first start icx-proxy
icx-proxy --address 127.0.0.1:8453 -vv &
icxproxypid=$!

result=$(curl "http://127.0.0.1:8453/storage?fileId=$fileId&chunkNum=1&canisterId=$bucketId")

[[ $result == "testfile" ]] && echo "test passed" || echo "test failed"

kill $icxproxypid