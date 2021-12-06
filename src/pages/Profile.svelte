<!-- display profile information -->

<script lang="ts">
import { onMount } from "svelte";
import { Col, Container, Row } from "sveltestrap";
import {fetchAuthors } from "../lib/blogStore"

let authors=[]
export let params={authorId:""}
onMount(async () => {
    authors=await fetchAuthors(params.authorId)
    console.log(authors)
})
</script>

{#each authors as {id, firstName, lastName, imgUrl, company, companyPosition, email}}
<Container>
    <Row>
        <Col xs="3"><img src="{imgUrl}" alt="" width=100px height=100px class="border-round"></Col>
        <Col>
            <h1>
                {firstName} {lastName}
            </h1>
        </Col>
        <Col>
            {companyPosition} at {company}
        </Col>
        <Col>
            <a href = "mailto: {email}">{email}</a>
        </Col>
    </Row>
</Container>    
{/each}

