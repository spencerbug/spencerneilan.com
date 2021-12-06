
<script lang="ts">
    import Router from 'svelte-spa-router'
    import { Button } from 'sveltestrap';
    import Article from './blog/Article.svelte';
    import BlogHome from './blog/BlogHome.svelte';
    import { push } from 'svelte-spa-router'
    import Editor from './blog/Editor.svelte';
    import { onMount } from 'svelte';
    
    const prefix='/blog'
    const routes = {
        '/':BlogHome,
        '/:articleId':Article,
        '/:articleId/edit':Editor
    }

</script>


<Router {routes} {prefix}/>



