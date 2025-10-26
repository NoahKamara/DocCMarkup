## DocCMarkup

A lightweight Swift library for parsing Swift-style documentation comments and Markdown into a small, structured model you can use in tools and tests.

- **Abstract and discussion parsing** from documentation text
- **Tag extraction (limited public surface for now)**: parameters, returns, throws, and simple list-item tags like "note"
- **HTTP-oriented tags (early)**: HTTP request/response bits are modeled for future expansion

> Detailed DocC documentation will be added later.

### Requirements
- **Swift**: 6.2 (swift-tools-version 6.2)
- **Platforms**: macOS 13+

### Installation (Swift Package Manager)
Add the package to your `Package.swift` or through Xcode:

```swift
dependencies: [
    .package(url: "https://github.com/noahkamara/DocCMarkup", branch: "main")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["DocCMarkup"]
    )
]
```

### Usage

Minimal examples to get started. The public API is intentionally small; more docs and surface area will come later.

Parse from a plain Markdown string:

```swift
import DocCMarkup

let doc = DocumentationMarkup(parsing: """
Lorem ipsum dolor sit amet.

Some discussion text.

- Returns: A result value.
- Throws: An error on failure.
""")

// Access abstract (first paragraph)
let abstract = doc.abstractSection?.content

// Access discussion as a formatted string
let discussionText = doc.discussionSection?.format()
```

Parse from SwiftSyntax trivia (documentation comments):

```swift
import DocCMarkup
import SwiftSyntax

let trivia: Trivia = [
    .docLineComment("/// A short description."),
    .docLineComment("///"),
    .docLineComment("/// More details here."),
]

let doc = DocumentationMarkup(trivia: trivia)
let abstract = doc.abstractSection?.content
```

### Running Tests

```bash
swift test
```


### ToDos

- HTTP parsing improvements
  - HTTPResponse parsing: Parse status code and reason from tags like `- HTTPResponse 200 OK:`; set `statusCode: UInt?` (nil if non-numeric) and `reason` when present; skip entry when neither parse is meaningful.
  - HTTPParameter parsing: Recognize simple source hints like `query`, `path`, `header` and required markers like `(required)`; populate `source` and `required` heuristically when present; otherwise leave `nil`/`false`.

- Conformances and access control polish
  - Add `Sendable` to public value types where feasible (`AbstractSection`, `DiscussionSection`, `Parameter`, `ParametersSection`, `Return`, `ReturnsSection`, `Throw`, `HTTPBody`, `HTTPParameter`, `HTTPResponse`, `TaggedComponents`).
  - Ensure public initializers/properties have intended visibility; avoid exposing mutation where not needed.

- Package hygiene
  - Pin dependency versions (avoid `branch: "main"` for `swift-markdown` and `swift-docc-symbolkit`).
  - Remove macro target fully; delete/ignore `Sources/DocCMarkupMacros/*` (no macros in this package).
  - Leave `VyperTests` as-is locally (not committed) — no package changes needed.

