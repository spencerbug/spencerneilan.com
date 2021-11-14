import { defineConfig } from 'vite'
import {svelte} from '@sveltejs/vite-plugin-svelte'
import dfxJson from "./dfx.json"
import path from "path"
import scss from "rollup-plugin-scss";
import * as fs from 'fs'
import {HTMLElement, parse, TextNode} from 'node-html-parser'

let localCanisters, prodCanisters, canisters;

function initCanisterIds() {
  try {
    localCanisters = require(path.resolve(
      ".dfx",
      "local",
      "canister_ids.json"
    ));
  } catch (error) {
    console.log("No local canister_ids.json found. Continuing production");
  }
  try {
    prodCanisters = require(path.resolve("canister_ids.json"));
  } catch (error) {
    console.log("No production canister_ids.json found. Continuing with local");
  }

  const network = process.env.DFX_NETWORK || "local";

  canisters = network === "local" ? localCanisters : prodCanisters;

  for (const canister in canisters) {
    process.env["VITE_APP_" + canister.toUpperCase() + "_CANISTER_ID"] =
      canisters[canister][network];
  }
}
initCanisterIds();

// List of all aliases for canisters
const aliases = Object.entries(dfxJson.canisters).reduce(
  (acc, [name, _value]) => {
    // Get the network name, or `local` by default.
    const networkName = process.env["DFX_NETWORK"] || "local";
    const outputRoot = path.join(
      __dirname,
      ".dfx",
      networkName,
      "canisters",
      name
    );

    return {
      ...acc,
      ["dfx-generated/" + name]: path.join(outputRoot, name + ".did.js"),
    };
  },
  {}
);

// https://vitejs.dev/config/
export default defineConfig(() => {
  return {
    plugins: [
      svelte({
        emitCss: true,
      }),
      scss({
        watch:"src",
        output: path.resolve('dist/assets/main.css'),
      }),
    ],
    resolve: {
      alias: {
        ...aliases,
      },
    },
    build: {
      rollupOptions: {
        plugins: [
          {
            name: 'add-css-link-to-html-head',
            closeBundle() {
              const data = fs.readFileSync('dist/index.html')
              const doc = parse(data)
              const head = doc.querySelector('head')
              const styleLink = new HTMLElement('link',{}, 'rel="stylesheet" href="/assets/main.css"', head)
              head.appendChild(styleLink)
              const source = '<!doctype html>\n' + doc.toString()
              let result = fs.writeFileSync('dist/index.html', source)
            },
          },
        ]
      }
    },
    define: {
      "process.env": process.env
    },
  }
})
