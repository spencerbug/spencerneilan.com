<script>
    import {createEventDispatcher} from 'svelte'
    import { Form, FormGroup, Button, Input, Label } from 'sveltestrap'
    export let myAccount = {}

    
    const dispatch = createEventDispatcher()

    const handleRegister = () => {
        dispatch("submit", {
            myAccount
        })
    }
</script>

<form on:submit|preventDefault={handleRegister}>
    <FormGroup>
        <Label for="firstName">First Name</Label>
        <Input type="text" bind:value={myAccount.firstName} id="firstName"/>
    </FormGroup>
    <FormGroup>
        <Label for="lastName">Last Name</Label>
        <Input type="text" bind:value={myAccount.lastName} id="lastName"/>
    </FormGroup>
    <FormGroup>
        <Label for="company">Company</Label>
        <Input type="text" bind:value={myAccount.company} id="company"/>
    </FormGroup>
    <FormGroup>
        <Label for="companyPosition">Company Position</Label>
        <Input type="text" bind:value={myAccount.companyPosition} id="companyPosition"/>
    </FormGroup>
    <FormGroup>
        <Label for="email">Email</Label>
        <Input type="email" bind:value={myAccount.email} id="email"/>
    </FormGroup>
    <FormGroup>
        <Label for="imgUrl">Image URL</Label>
        <Input type="text" bind:value={myAccount.imgUrl} id="imgUrl"/>
    </FormGroup>
    <Button type="submit">Register</Button>

</form>

