//
//  TaggedComponents.swift
//
//  Copyright © 2024 Noah Kamara.
//

import Foundation
import Markdown

/// The list of tags that can appear at the start of a list item to indicate
/// some meaning in the markup, taken from Swift documentation comments. These
/// are maintained for backward compatibility but their use should be
/// discouraged.
private let simpleListItemTags = [
    "attention",
    "author",
    "authors",
    "bug",
    "complexity",
    "copyright",
    "date",
    "experiment",
    // asides handled specially at top-level: note, important, warning, tip, seealso
    "invariant",
    "localizationkey",
    "mutatingvariant",
    "nonmutatingvariant",
    "postcondition",
    "precondition",
    "remark",
    "remarks",
    "returns",
    "throws",
    "requires",
    "since",
    "tag",
    "todo",
    "version",
    "keyword",
    "recommended",
    "recommendedover",
]

public struct TaggedComponents {
    public internal(set) var parameters = [Parameter]()
    public internal(set) var httpResponses = [HTTPResponse]()
    public internal(set) var httpParameters = [HTTPParameter]()
    public internal(set) var httpBody: HTTPBody?
    public internal(set) var returns = [Return]()
    public internal(set) var `throws` = [Throw]()
    public internal(set) var otherTags = [SimpleTag]()

    public init() {}
}

// Note: Rewriter logic has moved into DocumentationMarkupParser.
