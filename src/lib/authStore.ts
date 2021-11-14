import { writable, get } from "svelte/store";

import type { Identity } from "@dfinity/agent";
import {Actor, HttpAgent} from "@dfinity/agent";
import {authClient} from "./authClient"
import {idlFactory as storage_idl} from "dfx-generated/storage"
import {push} from 'svelte-spa-router'
import { GraphqlClient } from "./graphqlClient";

// authStore should be called first before contentStore, since this file declares the actors

export const s_authLoading = writable(false)
export const s_authDataLoading = writable(false)
export const s_hasAccount = writable(false)
export const s_identity = writable(null)
export const s_myAccount = writable({firstName: "",lastName: "",company: "",companyPosition: "",email: "",imgUrl: ""})
export const s_isLoggedIn = writable(false)
export const s_agent = writable(null)
export const s_storageActor = writable(null)
export const s_graphqlClient = writable(null)


export const handleAuthenticated = async () => {
    let identity:Identity = get(s_identity)
    if (import.meta.env.MODE == "development"){
        s_agent.set(new HttpAgent({identity, host:"http://localhost:8000"}))
    }
    else {
        s_agent.set(new HttpAgent({identity}))
    }
    s_isLoggedIn.set(await authClient.isAuthenticated())
    let agent:HttpAgent = get(s_agent)
    agent.fetchRootKey()
    let storageActor=Actor.createActor(storage_idl, {agent, canisterId:process.env["VITE_APP_STORAGE_CANISTER_ID"]})
    s_graphqlClient.set(new GraphqlClient(agent))

    s_storageActor.set(storageActor)
}

export const authInit = async () => {
    await authClient.create()
    let identity:Identity = await authClient.getIdentity()
    s_identity.set(identity)
    if (identity) {
        await handleAuthenticated()
        await handleLoadMyAccount()
    }

}

export const handleLogin = async () => {
    s_authLoading.set(true)
    await authClient.login()
    let identity:Identity = await authClient.getIdentity()
    s_identity.set(identity)
    if (identity) {
        await handleAuthenticated()
        //Bug:Seems we need a slight delay between login and contract calls, to ensure we get our account data the first time
        // await new Promise(r => setTimeout(r, 500))
        await handleLoadMyAccount()
    }
    s_authLoading.set(false)
}

export const handleLogout = async () => {
    await authClient.logout()
    s_isLoggedIn.set(false)
    s_hasAccount.set(false)
    s_identity.set(null)
    s_myAccount.set({firstName: "",lastName: "",company: "",companyPosition: "",email: "",imgUrl: ""})
    push("/")
}

export const registerOrUpdateMyAccount = async () => {
    const isLoggedIn:boolean = get(s_isLoggedIn)
    const identity:Identity = get(s_identity)
    const myAccount = get(s_myAccount)
    const hasAccount:boolean = get(s_hasAccount)
    const graphqlClient:GraphqlClient = get(s_graphqlClient)
    
    if (identity && isLoggedIn && graphqlClient) {
        s_authDataLoading.set(true)
        const mutateFn = (hasAccount ? "updateAccount" : "createAccount")
        const mutation = {
            mutation: {
                [mutateFn]: {
                    __args: {
                        input: {
                            id: identity.getPrincipal().toString(),
                            ...myAccount
                        }
                    },
                    id: true
                }
            }
        }
        const result = await graphqlClient.mutation(mutation)
        s_hasAccount.set(true)
        s_authDataLoading.set(false)
    }
}


export const handleLoadMyAccount = async () => {
    const identity:Identity = get(s_identity)
    const isLoggedIn:boolean = get(s_isLoggedIn)
    const graphqlClient:GraphqlClient = get(s_graphqlClient)
    if (identity && isLoggedIn && graphqlClient){
        s_authDataLoading.set(true)
        
        const query = {
            query: {
                readAccount: {
                    __args: {
                        search: {
                            id: {
                                eq: identity.getPrincipal().toString()
                            }
                        }
                    },
                    firstName: true,
                    lastName: true,
                    company: true,
                    companyPosition: true,
                    email: true,
                    imgUrl: true
                }
            }
        }
        const result = await graphqlClient.query(query)
        if (result.data?.readAccount.length > 0){
            s_hasAccount.set(true)
            s_myAccount.set(result.data.readAccount[0])
        }
        s_authDataLoading.set(false)
    }
}
