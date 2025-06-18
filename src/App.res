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
let decodeBlock = (json: Js.Json.t): block => {
  open Js.Json
  let dict = json->decodeObject->Belt.Option.getExn
  {
    canonical: dict
      ->Js.Dict.get("canonical")
      ->Belt.Option.getExn
      ->decodeBoolean
      ->Belt.Option.getWithDefault(false),
    blockHeight: dict
      ->Js.Dict.get("blockHeight")
      ->Belt.Option.getExn
      ->decodeNumber
      ->Belt.Option.getExn
      ->Belt.Float.toInt,
    stateHash: dict
      ->Js.Dict.get("stateHash")
      ->Belt.Option.getExn
      ->decodeString
      ->Belt.Option.getExn,
    coinbaseReceiverUsername: dict
      ->Js.Dict.get("coinbaseReceiverUsername")
      ->Belt.Option.flatMap(decodeString),
    snarkFees: dict
      ->Js.Dict.get("snarkFees")
      ->Belt.Option.getExn
      ->decodeString
      ->Belt.Option.getExn,
  }
}

// Decode the GraphQL response (data.blocks)
let decodeBlocks = (json: Js.Json.t): array<block> => {
  open Js.Json
  let data = json->decodeObject->Belt.Option.getExn
  let blocks = data
    ->Js.Dict.get("data")
    ->Belt.Option.getExn
    ->decodeObject
    ->Belt.Option.getExn
  blocks
    ->Js.Dict.get("blocks")
    ->Belt.Option.getExn
    ->decodeArray
    ->Belt.Option.getExn
    ->Belt.Array.map(decodeBlock)
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
  blocks
  ->Belt.Array.map(block =>
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
  ->Belt.Array.joinWith("", x => x)
}

let main = async () => {
  switch document->Document.getElementById("app") {
  | Some(container) =>
    let blocks = await fetchData()
    Element.setInnerHTML(
      container,
      `<div class="container mx-auto p-4">
         <h1 class="text-3xl font-bold text-blue-600 mb-4">Mina Blockchain Blocks</h1>
         <ul>${renderBlocks(blocks)}</ul>
       </div>`,
    )
  | None => Console.error("Error: Element with id 'app' not found")
  }
}

let handleDOMContentLoaded = (_event: Dom.event) => {
  main()->ignore
}

document->Document.addEventListener("DOMContentLoaded", handleDOMContentLoaded)
