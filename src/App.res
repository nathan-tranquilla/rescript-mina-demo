open Webapi.Dom
open Webapi.Fetch

// Type for a block from the Mina GraphQL API
type block = {
  canonical: bool,
  blockHeight: int,
  stateHash: string,
  coinbaseReceiverUsername: option<string>,
  snarkFees: string,
}

// Decode a single block from JSON
let decodeBlock = json => {
  open Js.Json
  open Js.Dict
  open Belt.Option
  switch json->decodeObject {
  | Some(dict) => {
      canonical: dict->get("canonical")->flatMap(decodeBoolean)->getWithDefault(false),
      blockHeight: dict->get("blockHeight")->flatMap(decodeNumber)->map(Belt.Float.toInt)->getWithDefault(0),
      stateHash: dict->get("stateHash")->flatMap(decodeString)->getWithDefault(""),
      coinbaseReceiverUsername: dict->get("coinbaseReceiverUsername")->flatMap(decodeString),
      snarkFees: dict->get("snarkFees")->flatMap(decodeString)->getWithDefault("0"),
    }
  | None => {
      canonical: false,
      blockHeight: 0,
      stateHash: "",
      coinbaseReceiverUsername: None,
      snarkFees: "0",
    }
  }
}

// Decode the GraphQL response (data.blocks)
let decodeBlocks = json => {
  open Js.Json
  open Js.Dict
  open Belt.Option
  switch json->decodeObject->flatMap(dict => dict->get("data"))->flatMap(decodeObject)->flatMap(dict => dict->get("blocks"))->flatMap(decodeArray) {
  | Some(blocks) => blocks->Belt.Array.map(decodeBlock)
  | None => []
  }
}

let fetchData = async () => {
  let query = `{
    blocks(limit: 10) {
      canonical
      blockHeight
      stateHash
      coinbaseReceiverUsername
      snarkFees
    }
  }`

  let payload = Js.Dict.empty()
  Js.Dict.set(payload, "query", Js.Json.string(query))
  try {
    let response = await fetchWithInit(
      "https://api.minasearch.com/graphql",
      RequestInit.make(
        ~method_=Post,
        ~body=BodyInit.make(Js.Json.stringify(Js.Json.object_(payload))),
        ~headers=HeadersInit.make({
          "Content-Type": "application/json",
          "Accept": "application/json, multipart/mixed",
        }),
        (),
      ),
    )
    let json = await Response.json(response)
    decodeBlocks(json)
  } catch {
  | _ => {
      Console.error("Failed to fetch Mina blocks")
      []
    }
  }
}

let renderBlocks = (blocks: array<block>): string => {
  open Belt.Array
  blocks
  ->map(block =>
    `<li class="mb-4 p-4 bg-gray-100 rounded-lg">
       <h2 class="text-xl font-semibold text-blue-600">Block ${block.blockHeight->Belt.Int.toString}</h2>
       <p class="text-gray-600"><strong>State Hash:</strong> ${block.stateHash}</p>
       <p class="text-gray-600"><strong>Canonical:</strong> ${block.canonical ? "Yes" : "No"}</p>
       <p class="text-gray-600"><strong>Coinbase Receiver:</strong> ${switch block.coinbaseReceiverUsername {
         | Some(username) => username
         | None => "None"
       }}</p>
       <p class="text-gray-600"><strong>Snark Fees:</strong> ${block.snarkFees}</p>
     </li>`
  )
  ->joinWith("", x => x)
}

let main = async () => {
  switch document->Document.getElementById("app") {
  | Some(container) =>
    // Show loading state
    Element.setInnerHTML(
      container,
      `<div class="container mx-auto p-4">
         <h1 class="text-3xl font-bold text-blue-600 mb-4">Mina Blockchain Blocks</h1>
         <p class="text-gray-600">Loading...</p>
       </div>`,
    )
    let blocks = await fetchData()
    // Render blocks or error
    Element.setInnerHTML(
      container,
      `<div class="container mx-auto p-4">
         <h1 class="text-3xl font-bold text-blue-600 mb-4">Mina Blockchain Blocks</h1>
         ${Belt.Array.length(blocks) == 0
           ? `<p class="text-red-600">Failed to load blocks</p>`
           : `<ul>${renderBlocks(blocks)}</ul>`}
       </div>`,
    )
  | None => Console.error("Error: Element with id 'app' not found")
  }
}

let handleDOMContentLoaded = (_event: Dom.event) => {
  main()->ignore
}

document->Document.addEventListener("DOMContentLoaded", handleDOMContentLoaded)
