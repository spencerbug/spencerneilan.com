<script>
import { onMount } from "svelte";
import { fetchAuthors } from "../../lib/blogStore"
import { link, push } from "svelte-spa-router"
import { Accordion, AccordionItem, Badge, Card, CardBody, CardTitle, CardSubtitle, CardFooter, CardText, Button } from "sveltestrap"
import { s_hasAccount } from "../../lib/authStore";

const prefix='blog'
let authors=[]

onMount(async () => {
    authors = await fetchAuthors(null);
    // console.log(authors)
})
</script>

<h1>
    Blog showcase
</h1>
<Accordion stayOpen>
    {#each authors as {
        id, firstName, lastName, imgUrl, articles
    }}
    <AccordionItem active>
        <div slot="header">
            <div class="row">
                <div class="col-3">
                    <a href="#/profile/{id}">
                        <img src="{imgUrl}" alt="{firstName}.{lastName}"
                            width="50px" height="50px" class="rounded-circle">
                    </a>
                </div>
                <div class="col">
                    <a href="#/profile/{id}" class="link-primary">
                        <h4 my-auto mx-auto>
                            {firstName} {lastName}
                        </h4>
                    </a>
                </div>
            </div>
        </div>
        {#each articles as {id, title, description, publishedAt, tags}}
        <a href="/{prefix}/{id}" use:link>
                <Card>
                    <CardTitle>{title}</CardTitle>
                    <CardBody>
                        <CardSubtitle>Published on {new Date(publishedAt)}</CardSubtitle>
                        <CardText>{description}</CardText>
                    </CardBody>
                    <CardFooter>
                        {#if tags}{#each tags as {id}}
                        <Badge class="inline-block">
                            {id}
                        </Badge>
                        {/each}{/if}
                    </CardFooter>
                </Card>
        </a>
        {/each}
    </AccordionItem>
    {/each}
</Accordion>

{#if $s_hasAccount}
<hr/>
<Button on:click={()=>{
    push(`/${prefix}/new/edit`)
}}>New Article</Button>
{/if}