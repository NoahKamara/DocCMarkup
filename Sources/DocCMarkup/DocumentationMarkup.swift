//
//  DocumentationMarkup.swift
//
//  Copyright © 2024 Noah Kamara.
//

import Foundation
import Markdown
import SwiftSyntax

/// A structured documentation markup data model.
///
/// ## Discussion
/// `DocumentationMarkup` parses a given piece of structured markup and provides access to the
/// documentation content.
///
/// ### Abstract
/// The parser parses the abstract from the first leading paragraph (skipping the comments) in the
/// markup after the title. If the markup doesn't start with a paragraph after the title heading,
/// it's considered to not have an abstract.
/// ```
/// # My Document
/// An abstract shortly describing My Document.
/// ```
/// ### Discussion
/// The parser parses the discussion from the end of the abstract section until the end of the
/// document.
/// ```
/// # My Document
/// An abstract shortly describing My Document.
/// ## Discussion
/// A discussion that may contain further level-3 sub-sections, text, images, etc.
/// ```
public struct DocumentationMarkup {
    /// The various sections that are expected in documentation markup.
    ///
    /// The cases in this enumeration are sorted in the order sections are expected to appear in the
    /// documentation markup.
    public enum ParseSection: Int, Comparable {
        public static func < (lhs: ParseSection, rhs: ParseSection) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        case abstract
        case discussion
        case end
    }

    // MARK: - Parsed Data

    /// The documentation abstract, if found.
    public private(set) var abstractSection: AbstractSection?

    /// The documentation Discussion section, if found.
    public private(set) var discussionSection: DiscussionSection?

    /// The documentation tags, if found.
    public private(set) var tags: TaggedComponents?

    // MARK: - Initialize and parse the markup

    /// Initialize a documentation model with the given markup.
    /// - Parameters:
    ///   - markup: The source markup.
    ///   - upToSection: Documentation past this section will be ignored.
    public init(markup: any Markup, upToSection lastSection: ParseSection = .end) {
        let result = DocumentationMarkupParser().parse(markup: markup, upToSection: lastSection)
        self.abstractSection = result.abstractSection
        self.discussionSection = result.discussionSection
        self.tags = result.tags
    }
}

// MARK: - Convenience Markup extensions

extension Markup {
    /// Returns a sub-sequence of the children sequence.
    /// - Parameter range: A closed range.
    /// - Returns: A children sub-sequence.
    func children(at range: ClosedRange<Int>) -> [any Markup] {
        let array = Array(self.children)
        guard !array.isEmpty else { return [] }
        let lower = max(range.lowerBound, 0)
        let upper = min(range.upperBound, array.count - 1)
        guard lower <= upper else { return [] }
        return Array(array[lower...upper])
    }

    /// Returns a sub-sequence of the children sequence.
    /// - Parameter range: A half-closed range.
    /// - Returns: A children sub-sequence.
    func children(at range: Range<Int>) -> [any Markup] {
        let array = Array(self.children)
        guard !array.isEmpty else { return [] }
        let lower = max(range.lowerBound, 0)
        let upper = min(range.upperBound, array.count)
        guard lower < upper else { return [] }
        return Array(array[lower..<upper])
    }
}
