<!-- Problem statement:
    Host videos and pictures,
    code examples
    WSYWYG type editor with ability to upload/drag and drop files, videos, and pictures.
    or just use straight html 
    drag and drop uploaded files will be hosted on dfinity using a scalable solution (bigmap or rendezvous distributed hash table)
    have a sidebar looking thing to navigate between articles
    articles have unique links with router
    dynamic slug based routing
 -->
<script lang="ts">
    import {Col, Container, Row, Collapse, Nav, NavbarBrand, Navbar, NavItem, NavbarToggler} from 'sveltestrap'
    import Button from 'sveltestrap/src/Button.svelte';
    import WSYWYG from '../components/WSYWYG.svelte'

    let isOpenJuly2021=false
    let isOpenJune2021=false
</script>



<Row>
    <Col md="9" class="rounded bg-light">
        <WSYWYG/>
    </Col>
    <Col md="3" class="rounded">

        <Button class="btn-block w-100" color="secondary" on:click={()=>(isOpenJuly2021=!isOpenJuly2021)}>July 2021</Button>
        <Collapse isOpen={isOpenJuly2021}>
            <p>July 6th 2021 4pm</p>
        </Collapse>
        <Button class="btn-block w-100" color="secondary" on:click={()=>(isOpenJune2021=!isOpenJune2021)}>June 2021</Button>
        <Collapse isOpen={isOpenJune2021}>
            <p>June 8th 2021 7:36pm</p>
        </Collapse>
    </Col>
</Row>
