import type {HttpAgent } from '@dfinity/agent'
import {Actor} from '@dfinity/agent'
import {idlFactory as graphql_idl} from "dfx-generated/graphql"
import type { _SERVICE as GraphqlActor } from 'src/backend/graphql/types'
import { writable } from 'svelte/store'
import { jsonToGraphQLQuery } from 'json-to-graphql-query';


const s_graphqlActor = writable(null)

export class GraphqlClient {
    public agent:HttpAgent
    public actor:GraphqlActor
    constructor(agent) {
        this.agent = agent
        this.actor = Actor.createActor(graphql_idl, {agent, canisterId:process.env["VITE_APP_GRAPHQL_CANISTER_ID"]})
        return this
    }

    // takes in a json object following https://www.npmjs.com/package/json-to-graphql-query
    async query(queryJSON:any) {
        const queryString = jsonToGraphQLQuery(queryJSON)
        // console.log(queryString)
        const result = await this.actor.graphql_query(queryString, '{}')
        const resultJSON = JSON.parse(result as string)
        return resultJSON
    }

    async mutation(mutationJSON:any) {
        const queryString = jsonToGraphQLQuery(mutationJSON)
        // console.log(queryString)
        const result = await this.actor.graphql_mutation(queryString, '{}')
        const resultJSON = JSON.parse(result as string)
        return resultJSON
    }


}