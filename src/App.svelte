<script lang="ts">
  import logo from './assets/logo.svg'
  import Nav from './lib/Nav.svelte'
  import Register from './lib/Register.svelte'
  import {authClient} from './authClient'
  // import { accounts } from "./agent"
  import {idlFactory as accounts_idl, canisterId as accounts_id} from "dfx-generated/accounts"
  import {Styles} from 'sveltestrap'
  import { onMount } from 'svelte';
  import { Actor, HttpAgent } from '@dfinity/agent';


  

  let accountsActor=null
  let isLoggedIn=false
  let hasAccount=false
  let myAccount={}
  let isloading=false

  onMount(async () => {
    await authClient.create()
  })


  const handleLoginButton = async(event) => {
    let identity = await authClient.login()
    if (identity != undefined) {
      isLoggedIn=true
    }
    let agent
    if (import.meta.env.MODE == "development"){
      agent = new HttpAgent({identity, host:"http://localhost:8000"})
    }
    else {
      agent = new HttpAgent({identity})
    }
    accountsActor = Actor.createActor(accounts_idl, {agent, canisterId: accounts_id})
    let tmpAccount:Array<Object> = await accountsActor.getMyAccount()
    hasAccount = (tmpAccount.length > 0)
    if (hasAccount) {
      myAccount=tmpAccount[0]
    }
    
  }


  const handleRegister = async (event) => {
    let newAccount = event.detail.myAccount
    console.log(newAccount)
    if (isLoggedIn && accountsActor){
      isloading=true
      let result = await accountsActor.upsertMyAccount(myAccount)
      isloading=false
      let resultAccount = await accountsActor.getMyAccount()
      console.log(resultAccount)
    }
  }

  const handleLogoutButton = async () => {
    await authClient.logout()
    isLoggedIn=false
    hasAccount=false
  }

</script>

<Styles/>

<main>
  <Nav />
  {#if isLoggedIn}
    <button on:click={handleLogoutButton}>Logout</button>
    <Register bind:myAccount on:submit={handleRegister}/>
  {:else}
    <button on:click={handleLoginButton}>Login</button>
  {/if}
  {#if isloading}
  <p>Loading</p>
  {/if}
</main>

<style>
  :root {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen,
      Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
  }

  main {
    text-align: center;
    padding: 1em;
    margin: 0 auto;
  }

  img {
    height: 16rem;
    width: 16rem;
  }

  p {
    max-width: 14rem;
    margin: 1rem auto;
    line-height: 1.35;
  }

  @media (min-width: 480px) {
    h1 {
      max-width: none;
    }

    p {
      max-width: none;
    }
  }
</style>
