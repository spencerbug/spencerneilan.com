<script lang="ts">
  import logo from './assets/logo.svg'
  import Nav from './components/Nav.svelte'
  import Register from './components/Register.svelte'
  import Home from './components/Home.svelte'
  import Projects from './components/Projects.svelte'
  import {Styles} from 'sveltestrap'
  import { onMount } from 'svelte';
  import {s_dataLoading, s_authLoading, authInit} from './lib/authStore'
  import Router from 'svelte-spa-router'


  onMount(async () => {
    await authInit()
  })

</script>

<Styles/>

<main>
  <Nav/>
  {#if $s_dataLoading}
  <h1>Loading submission...</h1>
  {:else if $s_authLoading}
  <h1>Loading auth...</h1>
  {:else}
  <Router routes={{
    '/': Home,
    '/register': Register,
    '/projects': Projects,
  }}/>
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
