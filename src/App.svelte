<script lang="ts">
  import Nav from './components/Nav.svelte'
  import Register from './pages/Register.svelte'
  import Home from './pages/Home.svelte'
  import Blog from './pages/Blog.svelte'
  import Projects from './pages/Projects.svelte'
  import Resume from './pages/Resume.svelte'
  import {Styles, Spinner} from 'sveltestrap'
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
  <h1><Spinner color="info"/></h1>
  {:else}
  <Router routes={{
    '/': Home,
    '/register': Register,
    '/projects': Projects,
    '/blog':Blog,
    '/resume':Resume
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

  }
</style>
