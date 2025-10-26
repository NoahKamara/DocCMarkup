//
//  DocumentationMarkup+Parsing.swift
//
//  Copyright © 2024 Noah Kamara.
//

import Markdown
import SwiftSyntax

public extension DocumentationMarkup {
    init(trivia: Trivia) {
        let markup = trivia.reduce(into: "") { result, piece in
            switch piece {
            case .docLineComment(let string): result += "\n" + string
            case .docBlockComment(let string): result += "\n" + string
            default:
                break
            }
        }

        self.init(parsing: markup)
    }

    /// Parse documentation markup from string
    /// - Parameter text: the documentation markup text
    init(parsing text: consuming String) {
        var working = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove documentation comment trivia if present
        if working.hasPrefix("///") {
            // Handle doc line comments with or without trailing whitespace or tabs.
            let lines = working.split(separator: "\n", omittingEmptySubsequences: false)
            let processed = lines.map { line -> String in
                var s = String(line)
                guard s.hasPrefix("///") else { return s }
                s.removeFirst(3)
                if let first = s.first, first == " " || first == "\t" {
                    s.removeFirst()
                }
                return s
            }
            working = processed.joined(separator: "\n")
        } else if working.hasPrefix("/**") {
            // Handle doc block comments: strip wrapper and leading '*' per line + surrounding
            // whitespace.
            working.removeFirst(3) // remove "/**"
            if working.hasSuffix("*/") {
                working.removeLast(2)
            }
            let lines = working.split(separator: "\n", omittingEmptySubsequences: false)
            let processed = lines.map { line -> String in
                var s = String(line)
                // Trim leading spaces/tabs
                s.trimPrefix(while: { $0.isWhitespace })
                if s.first == "*" {
                    s.removeFirst()
                    if let first = s.first, first == " " || first == "\t" {
                        s.removeFirst()
                    }
                }
                return s
            }
            working = processed.joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let document = Markdown.Document(parsing: working, options: [.parseSymbolLinks])
        self.init(markup: document)
    }
}
