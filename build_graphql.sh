#!/usr/bin/env bash

cargo build --target wasm32-unknown-unknown --release --package graphql && \
 ic-cdk-optimizer ./target/wasm32-unknown-unknown/release/graphql.wasm -o ./target/wasm32-unknown-unknown/release/graphql-opt.wasm