import type { Identity } from '@dfinity/agent';
import { AuthClient } from '@dfinity/auth-client';

const IDENTITY_URL = 
    import.meta.env.VITE_INTERNET_IDENTITY_URL ||
    'https://identity.ic0.app'


class AuthClientWrapper {
    public authClient?:AuthClient;
    public ready = false;
    constructor() {
        return this
    }

    async create() {
        this.authClient = await AuthClient.create()
        await this.authClient?.isAuthenticated()
        this.ready = true
    }

    async login(): Promise<Identity | undefined> {
        return new Promise(async (resolve) => {
            await this.authClient?.login({
                identityProvider:<string|URL>IDENTITY_URL,
                onSuccess: async () => {
                    resolve(this.authClient?.getIdentity())
                }
            })
        })
    }

    async logout() {
        return this.authClient?.logout({returnTo: '/'})
    }

    async getIdentity() {
        return this.authClient?.getIdentity()
    }

    async isAuthenticated() {
        return this.authClient?.isAuthenticated()
    }

}

export const authClient = new AuthClientWrapper()
