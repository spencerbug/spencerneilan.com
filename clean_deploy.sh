#!/bin/bash


result=$(dfx canister call storage listBuckets)
if [ $? ]; then
    bucketIds=$(echo $result | grep principal | awk -F'"' '{print $2}')

    echo "deleting bucket canisters"
    while IFS= read -r id; do
        dfx canister stop $id
        dfx canister delete $id
    done <<< "$bucketIds"
    dfx canister uninstall-code storage
    dfx canister uninstall-code graphql
fi

dfx deploy