<script lang="ts">
    import {s_isLoggedIn, s_hasAccount, s_myAccount, handleLogin, handleLogout, s_authLoading} from '../lib/authStore'
    import {
        Collapse,
        Navbar,
        NavbarToggler,
        NavbarBrand,
        Nav,
        NavItem,
        NavLink,
        Dropdown,
        DropdownToggle,
        DropdownMenu,
        DropdownItem,
        Spinner} from 'sveltestrap'

    let isOpen = false;
    function handleUpdate(event) {
        isOpen = event.detail.isOpen
    }


    // right navbar dropdown states:
    // not logged in: Log in with Dfinity
    // logged in but unregistered: Welcome stranger -> register new account, logout
    // logged in and recognized: Welcome {username}! -> My account, logout

</script>

<style>
    .icon {
        /* width: 4em; */
        height: 1em;
        display: inline;
        margin-bottom: 3px;
        /* margin-right: 20px; */
        vertical-align: bottom;
    }
</style>

<Navbar color="primary" class="navbar-dark" light expand="md">
    <NavbarBrand href="#">Spencer Neilan</NavbarBrand>
    <NavbarToggler on:click={() => (isOpen = !isOpen)} />
    <Collapse {isOpen} navbar expand="md" on:update={handleUpdate}>
        <Nav class="me-auto" navbar>
        <NavItem><NavLink href="#">Home</NavLink></NavItem>
        <NavItem><NavLink href="#/projects">Projects</NavLink></NavItem>
        <NavItem><NavLink href="#/blog">Blog</NavLink></NavItem>
        <NavItem><NavLink href="#/resume">Resume</NavLink></NavItem>
        </Nav>
        <Nav class="ms-auto" navbar>
        {#if $s_authLoading}
        <Spinner color="info"/>
        {/if}
        {#if !$s_isLoggedIn}
            <NavItem>
                <NavLink on:click={async () => await handleLogin()}>
                    Log in with <span><img src="dfinity-logo-vector-small.svg" class="icon" alt="Dfinity Logo"></span>
                </NavLink>
            </NavItem>
        {:else}
            <Dropdown nav inNavbar>
                {#if $s_hasAccount}
                <DropdownToggle nav caret>Hello, {$s_myAccount.firstName}</DropdownToggle>
                {:else}
                <DropdownToggle nav caret>Hello, stranger! Please Register</DropdownToggle>
                {/if}
                <DropdownMenu end>
                    <DropdownItem href="#/register">My Account</DropdownItem>
                    <DropdownItem divider/>
                    <DropdownItem on:click={async () => await handleLogout()}>Logout</DropdownItem>
                </DropdownMenu>
            </Dropdown>
        {/if}
        </Nav>
    </Collapse>
</Navbar> 