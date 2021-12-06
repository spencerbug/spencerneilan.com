
# spencerneilan.com

## Written with svelte + typescript + vite

# start dfx Identity Server

You will need dfx.

``` bash
DFX_VERSION=0.8.3 sh -ci "$(curl -fsSL https://sdk.dfinity.org/install.sh)"
```

go to internet-identity project directory. You can get it from https://github.com/dfinity/internet-identity.git:

```bash
dfx start --background --clean --host=0.0.0.0:8000
II_ENV=development dfx deploy --no-wallet --argument '(null)'
```

open .dfx/local/canister_ids.json
and copy he internet_identity canister id
go through the following transformations:

``` bash
http://{canisters.internet-identity.id}.localhost:8000/

http://rwlgt-iiaaa-aaaaa-aaaaa-cai.localhost:8000/

INTERNET_IDENTITY_URL=http://rwlgt-iiaaa-aaaaa-aaaaa-cai.localhost:8000/
```

paste the last line above into .env.development in this project

# Deploy the project

``` bash
dfx deploy
```

# To upgrade bucket canister

Because the bucket canister is created by the storage canister, when you dfx deploy the bucket won't be ugpraded.
To workaround this, you will need ic-repl, and a shell script to upgrade bucket

First get ic-repl latest
*instructions TBD*

``` bash
git clone https://github.com/chenyan2002/ic-repl.git
cargo install --path ./ic-repl
```
