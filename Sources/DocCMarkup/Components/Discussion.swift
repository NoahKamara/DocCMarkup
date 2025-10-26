//
//  Discussion.swift
//
//  Copyright © 2024 Noah Kamara.
//

public import Markdown

public struct DiscussionSection {
    public var content: [String]

    /// Creates a new discussion section with the given markup content.
    public init(content: [any Markup]) {
        self.content = content.map { $0.format() }
    }

    public func format() -> String {
        self.content.joined(separator: "\n\n")
    }
}
