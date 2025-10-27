//
//  Abstract.swift
//
//  Copyright © 2024 Noah Kamara.
//

public import Markdown

/// A one-paragraph section that represents a symbol's abstract description.
public struct AbstractSection {
    public var content: [String]

    /// Creates a new section with the given paragraph.
    public init(paragraph: Paragraph) {
        self.content = paragraph.children.compactMap(\.detachedFromParent).map { $0.format() }
    }

    public init(content: [String]) {
        self.content = content
    }
}

extension AbstractSection: Codable {
    public func encode(to encoder: any Encoder) throws {
        try content.encode(to: encoder)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let content = try container.decode([String].self)
        self.init(content: content)
    }
}
