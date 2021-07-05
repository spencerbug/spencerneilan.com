import { writable, get } from "svelte/store";

import type { Identity } from "@dfinity/agent";
import {Actor, HttpAgent} from "@dfinity/agent";
import {authClient} from "./authClient"
import type {_SERVICE,Account} from "../backend/accounts/types"
import {idlFactory as accounts_idl, canisterId as accounts_id} from "dfx-generated/accounts"
import {push} from 'svelte-spa-router'

//todo: change this to a class

export const s_authLoading = writable(false)
export const s_dataLoading = writable(false)
export const s_hasAccount = writable(false)
export const s_identity = writable(null)
export const s_myAccount = writable({firstName: "",lastName: "",company: "",companyPosition: "",email: "",imgUrl: ""})
export const s_isLoggedIn = writable(false)
export const s_agent = writable(null)
export const s_accountsActor = writable(null)


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
    s_accountsActor.set(Actor.createActor(accounts_idl, 
        {agent, canisterId:accounts_id}))
}

export const authInit = async () => {
    await authClient.create()
    let identity:Identity = await authClient.getIdentity()
    s_identity.set(identity)
    if (identity) {
        await handleAuthenticated()
        await handleDataLoad()
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
        await handleDataLoad()
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

export const handleDataLoad = async () => {
    let isLoggedIn:boolean = get(s_isLoggedIn)
    let accountsActor:_SERVICE = get(s_accountsActor)
    let identity:Identity = get(s_identity)
    if (isLoggedIn && accountsActor && identity) {
        s_dataLoading.set(true)
        let tmpAccount:Array<Object> = await accountsActor.getMyAccount()
        if (tmpAccount.length > 0){
            s_hasAccount.set(true)
            s_myAccount.set(<Account>tmpAccount[0])
        }
        s_dataLoading.set(false)
    }
}

export const handleRegister = async () => {
    let isLoggedIn:boolean = get(s_isLoggedIn)
    let accountsActor:_SERVICE = get(s_accountsActor)
    if (isLoggedIn && accountsActor){
        s_dataLoading.set(true)
        let myAccount = get(s_myAccount)
        await accountsActor.upsertMyAccount(myAccount)
        s_hasAccount.set(true)
        s_dataLoading.set(false)
    }
}
