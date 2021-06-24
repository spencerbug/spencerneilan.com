import type {Principal} from "@dfinity/agent"

export interface Account {
    firstName: string,
    lastName: string,
    company: string,
    companyPosition: string,
    email: string,
    imgUrl: string
}

export interface _SERVICE {
    getAccount: (arg_0: Principal) => Promise<[]|[Account]>
    getMyAccount: () => Promise<[]|[Account]>
    upsertAccount: (arg_0:Principal, arg_1:Account) => Promise<undefined>
    upsertMyAccount: (arg_1:Account) => Promise<undefined>
    whoAmI: () => Promise<Principal>

}