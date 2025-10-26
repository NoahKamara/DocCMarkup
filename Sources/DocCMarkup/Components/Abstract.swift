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
}
