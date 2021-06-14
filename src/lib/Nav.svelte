<script lang="ts">
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
    DropdownItem} from 'sveltestrap'

    let isOpen = false;
    function handleUpdate(event) {
    isOpen = event.detail.isOpen
    }
</script>

<Navbar color="light" light expand="md">
    <NavbarBrand href="/#">Spencer Neilan</NavbarBrand>
    <NavbarToggler on:click={() => (isOpen = !isOpen)} />
    <Collapse {isOpen} navbar expand="md" on:update={handleUpdate}>
        <Nav class="me-auto" navbar>
        <NavItem><NavLink href="/#">Home</NavLink></NavItem>
        <NavItem><NavLink href="/#/projects">Projects</NavLink></NavItem>
        </Nav>
        <Nav class="ms-auto" navbar>
        <Dropdown nav inNavbar>
            <DropdownToggle nav caret>Options</DropdownToggle>
            <DropdownMenu end>
            <DropdownItem>Option1</DropdownItem>
            <DropdownItem>Option2</DropdownItem>
            <DropdownItem divider/>
            <DropdownItem>Reset</DropdownItem>
            </DropdownMenu>
        </Dropdown>
        </Nav>
    </Collapse>
</Navbar> 