<script>
    // import {createEventDispatcher} from 'svelte'
    import { Form, FormGroup, Button, Input, Label } from 'sveltestrap'
    import {s_myAccount, handleRegister, s_hasAccount } from "../lib/authStore"
    

    
</script>

<form on:submit|preventDefault={async event => await handleRegister()}>
    <FormGroup>
        <Label for="firstName">First Name</Label>
        <Input type="text" bind:value={$s_myAccount.firstName} id="firstName"/>
    </FormGroup>
    <FormGroup>
        <Label for="lastName">Last Name</Label>
        <Input type="text" bind:value={$s_myAccount.lastName} id="lastName"/>
    </FormGroup>
    <FormGroup>
        <Label for="company">Company</Label>
        <Input type="text" bind:value={$s_myAccount.company} id="company"/>
    </FormGroup>
    <FormGroup>
        <Label for="companyPosition">Company Position</Label>
        <Input type="text" bind:value={$s_myAccount.companyPosition} id="companyPosition"/>
    </FormGroup>
    <FormGroup>
        <Label for="email">Email</Label>
        <Input type="email" bind:value={$s_myAccount.email} id="email"/>
    </FormGroup>
    <FormGroup>
        <Label for="imgUrl">Image URL</Label>
        <Input type="text" bind:value={$s_myAccount.imgUrl} id="imgUrl"/>
    </FormGroup>
    {#if $s_hasAccount}
    <Button type="submit">Update</Button>
    {:else}
    <Button type="submit">Register</Button>
    {/if}

</form>

