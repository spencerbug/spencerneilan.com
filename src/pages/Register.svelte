<script>
import { uploadImage } from '../lib/storageStore';

// import {createEventDispatcher} from 'svelte'
import { Form, FormGroup, Button, Input, Label, Spinner, Icon } from 'sveltestrap'
import {s_myAccount, s_hasAccount, registerOrUpdateMyAccount } from "../lib/authStore"

let fileInput

const onImageSelected = async (e) => {
    imageLoading=true
    let img = await(uploadImage(e.target.files[0]))
    s_myAccount.update(state=>{
        state.imgUrl = img.url
        return state
    })
    await registerOrUpdateMyAccount()
    imageLoading=false
}
let imageLoading=false
    
</script>

<form on:submit|preventDefault={async event => await registerOrUpdateMyAccount()}>
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
        {#if imageLoading}
            <Spinner/>
        {:else}
            <Label for="imgUrl">Profile Image</Label>
            {#if $s_myAccount.imgUrl}
            <img src="{$s_myAccount.imgUrl}" alt="Your pic here" width=50px height=50px class="rounded-circle">
            {/if}
            <input type="file" name="avatar" accept="image" style="display:none" on:change={async (e)=>{await onImageSelected(e)}} bind:this={fileInput}/>

            <Button type="button" on:click={()=>{fileInput.click()}}>
                <Icon name="upload"/>
            </Button>
        {/if}
    </FormGroup>
    {#if $s_hasAccount}
    <Button type="submit">Update</Button>
    {:else}
    <Button type="submit">Register</Button>
    {/if}

</form>

