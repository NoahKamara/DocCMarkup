//
//  DocumentationMarkup+Parsing.swift
//  DocCMarkup
//
//  Created by Noah Kamara on 26.10.2025.
//

import SwiftSyntax
import Markdown

public extension DocumentationMarkup {
    init(trivia: Trivia) {
        let markup = trivia.reduce(into: "") { result, piece in
            switch piece {
            case .docLineComment(let string): result += "\n"+string
            case .docBlockComment(let string): result += "\n"+string
            default:

                break
            }
        }

        self.init(parsing: markup)
    }

    /// Parse documentation markup from string
    /// - Parameter text: the documentation markup text
    init(parsing text: consuming String, removeLeadingTrivia: Bool = false) {
        var text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // remove documentation comment trivia if found
        let prefix = text.prefix(3)
        if prefix == "///" {
            // remove leading trivia for each line
            text = text
                .split(separator: "\n")
                .map({ $0.trimmingPrefix("/// ") })
                .joined(separator: "\n")
        } else if prefix == "/**" {
            // trim surrounding trivia for block
            text.trimPrefix("/**")
            if text.hasSuffix("*/") {
                text.removeLast(2)
            }
            // trim single leading whitespace for each line
            text = text
                .split(separator: "\n")
                .map({ $0.trimmingPrefix(" ") })
                .joined(separator: "\n")
        }

        let document = Markdown.Document(parsing: text, options: [.parseSymbolLinks])
        self.init(markup: document)
    }
}
