let main = () => {
  switch Webapi.Dom.document->Webapi.Dom.Document.getElementById("app") {
  | Some(container) =>
    Webapi.Dom.Element.setInnerHTML(
      container,
      `<div class="container mx-auto p-4">
        <h1 class="text-3xl font-bold text-blue-600">Hello, World!</h1>
      </div>`,
    )
  | None => Console.error("Error: Element with id 'app' not found")
  }
}

let handleDOMContentLoaded = (_event: Dom.event) => main()

Webapi.Dom.document->Webapi.Dom.Document.addEventListener("DOMContentLoaded", handleDOMContentLoaded)
