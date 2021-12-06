<script lang="ts">
  import Nav from './components/Nav.svelte'
  import Register from './pages/Register.svelte'
  import Home from './pages/Home.svelte'
  import Blog from './pages/Blog.svelte'
  import Projects from './pages/Projects.svelte'
  import Resume from './pages/Resume.svelte'
  import {Spinner, Container} from 'sveltestrap'
  import { onMount } from 'svelte';
  import {s_authDataLoading, authInit} from './lib/authStore'
  import Router from 'svelte-spa-router'
  import Profile from './pages/Profile.svelte';



  onMount(async () => {
    await authInit()
  })

  // const prefix = `/${process.env["VITE_APP_ASSETS_CANISTER_ID"]}}`

</script>

<main>
  <Nav/>
  <Container>
    {#if $s_authDataLoading}
    <h1><Spinner color="info"/></h1>
    {:else}
    <Router routes={{
      '/': Home,
      '/register': Register,
      '/projects': Projects,
      '/blog':Blog,
      '/blog/*':Blog,
      '/resume':Resume,
      '/profile/:authorId':Profile
    }}/>
    {/if}
  </Container>
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


  @media (min-width: 480px) {
    h1 {
      max-width: none;
    }

  }
</style>
