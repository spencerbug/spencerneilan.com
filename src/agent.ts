import { Actor, HttpAgent } from "@dfinity/agent"
import { idlFactory as accounts_idl, canisterId as accounts_id } from "dfx-generated/accounts"

const agentOptions = {
  host: "http://localhost:8000",
}

const agent = new HttpAgent(agentOptions)
const accounts = Actor.createActor(accounts_idl, { agent, canisterId: accounts_id })

export { accounts }