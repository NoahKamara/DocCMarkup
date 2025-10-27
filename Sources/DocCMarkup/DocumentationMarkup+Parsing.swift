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

// MARK: - Parser

struct DocumentationMarkupParser {
    struct Result {
        var abstractSection: AbstractSection?
        var discussionSection: DiscussionSection?
        var tags: TaggedComponents?
    }

    /// Rewriter that extracts tags and returns remainder content.
    struct Rewriter: MarkupRewriter {
        var tags = TaggedComponents()

        // MARK: Extracting tags information helpers (copied from old TaggedComponents)

        /// Information about an extracted tag
        struct ExtractedTag {
            var rawTag: String
            var knownTag: KnownTag?
            var tagRange: Markdown.SourceRange?
            var contents: [any Markup]
            var range: Markdown.SourceRange?

            init(
                rawTag: String,
                tagRange: Markdown.SourceRange?,
                contents: [any Markup],
                range: Markdown.SourceRange?
            ) {
                self.rawTag = rawTag
                self.knownTag = .init(rawTag)
                self.tagRange = tagRange
                self.contents = contents
                self.range = range
            }

            enum KnownTag {
                case returns
                case `throws`
                case parameter(String)
                case parameters

                case httpBody
                case httpResponse(String)
                case httpResponses
                case httpParameter(String)
                case httpParameters
                case httpBodyParameter(String)
                case httpBodyParameters

                init?(_ string: String) {
                    let separatorIndex = string.firstIndex(where: \.isWhitespace) ?? string.endIndex
                    let secondComponent = String(string[separatorIndex...]
                        .drop(while: \.isWhitespace))

                    switch string[..<separatorIndex].lowercased() {
                    case "returns": self = .returns
                    case "throws": self = .throws
                    case "parameter"
                        where !secondComponent.isEmpty: self = .parameter(secondComponent)
                    case "parameters": self = .parameters
                    case "httpbody": self = .httpBody
                    case "httpresponse"
                        where !secondComponent.isEmpty: self = .httpResponse(secondComponent)
                    case "httpresponses": self = .httpResponses
                    case "httpparameter"
                        where !secondComponent.isEmpty: self = .httpParameter(secondComponent)
                    case "httpparameters": self = .httpParameters
                    case "httpbodyparameter"
                        where !secondComponent.isEmpty: self = .httpBodyParameter(secondComponent)
                    case "httpbodyparameters": self = .httpBodyParameters
                    default: return nil
                    }
                }
            }

            func nameRange(name: String) -> Markdown.SourceRange? {
                if name == self.rawTag {
                    self.tagRange
                } else {
                    self.tagRange.map { tagRange in
                        let end = tagRange.upperBound
                        var start = end
                        start.column -= name.utf8.count
                        return start..<end
                    }
                }
            }
        }

        /// The list of simple tags
        let simpleListItemTags = [
            "attention", "author", "authors", "bug", "complexity", "copyright", "date",
            "experiment", "invariant", "localizationkey", "mutatingvariant", "nonmutatingvariant",
            "postcondition", "precondition", "remark", "remarks", "returns", "throws", "requires",
            "since", "tag", "todo", "version", "keyword", "recommended", "recommendedover",
        ]

        mutating func visitDocument(_ document: Document) -> (any Markup)? {
            let processedChildren: [any BlockMarkup] = document.children.compactMap {
                visit($0) as? (any BlockMarkup)
            }
            let processedDocument = Document(processedChildren)

            return processedDocument
        }

        mutating func visitUnorderedList(_ unorderedList: UnorderedList) -> (any Markup)? {
            var newItems = [ListItem]()
            for item in unorderedList.listItems {
                guard let newItem = visit(item) as? ListItem else {
                    continue
                }
                newItems.append(newItem)
            }
            guard !newItems.isEmpty else { return nil }
            return UnorderedList(newItems)
        }

        mutating func visitListItem(_ listItem: ListItem) -> (any Markup)? {
            do {
                guard let parent = listItem.parent,
                      parent.parent == nil || parent.parent is Document
                else {
                    return listItem
                }
            }

            guard let extractedTag = listItem.extractTag() else {
                return listItem
            }

            switch extractedTag.knownTag {
            case .returns:
                self.tags.returns.append(Return(
                    contents: extractedTag.contents,
                    range: extractedTag.range
                ))
            case .throws:
                self.tags.throws.append(Throw(contents: extractedTag.contents))
            case .parameter(let name):
                self.tags.parameters.append(
                    Parameter(
                        name: name,
                        nameRange: extractedTag.nameRange(name: name),
                        contents: extractedTag.contents,
                        range: extractedTag.range,
                        isStandalone: true
                    )
                )
            case .parameters:
                let params = listItem.extractInnerTagOutline().map { inner in
                    Parameter(
                        name: inner.rawTag,
                        nameRange: inner.nameRange(name: inner.rawTag),
                        contents: inner.contents,
                        range: inner.range,
                        isStandalone: false
                    )
                }
                self.tags.parameters.append(contentsOf: params)
            case .httpResponse(let name):
                self.tags.httpResponses.append(
                    HTTPResponse(
                        statusCode: UInt(name) ?? 0,
                        reason: nil,
                        mediaType: nil,
                        contents: extractedTag.contents
                    )
                )
            case .httpResponses:
                let responses = listItem.extractInnerTagOutline().map { inner in
                    HTTPResponse(
                        statusCode: UInt(inner.rawTag) ?? 0,
                        reason: nil,
                        mediaType: nil,
                        contents: inner.contents
                    )
                }
                self.tags.httpResponses.append(contentsOf: responses)
            case .httpBody:
                if self.tags.httpBody == nil {
                    self.tags.httpBody = HTTPBody(mediaType: nil, contents: extractedTag.contents)
                } else {
                    self.tags.httpBody?.contents = extractedTag.contents.map { $0.format() }
                }
            case .httpParameter(let name):
                self.tags.httpParameters.append(
                    HTTPParameter(name: name, source: nil, contents: extractedTag.contents)
                )
            case .httpParameters:
                let httpParams = listItem.extractInnerTagOutline().map { inner in
                    HTTPParameter(name: inner.rawTag, source: nil, contents: inner.contents)
                }
                self.tags.httpParameters.append(contentsOf: httpParams)
            case .httpBodyParameter(let name):
                let parameter = HTTPParameter(
                    name: name,
                    source: nil,
                    contents: extractedTag.contents
                )
                if self.tags.httpBody == nil {
                    self.tags.httpBody = HTTPBody(
                        mediaType: nil,
                        contents: [],
                        parameters: [parameter],
                        symbol: nil
                    )
                } else {
                    self.tags.httpBody?.parameters.append(parameter)
                }
            case .httpBodyParameters:
                let parameters = listItem.extractInnerTagOutline().map { inner in
                    HTTPParameter(name: inner.rawTag, source: nil, contents: inner.contents)
                }
                if self.tags.httpBody == nil {
                    self.tags.httpBody = HTTPBody(
                        mediaType: nil,
                        contents: [],
                        parameters: parameters,
                        symbol: nil
                    )
                } else {
                    self.tags.httpBody?.parameters.append(contentsOf: parameters)
                }
            case nil where self.simpleListItemTags.contains(extractedTag.rawTag.lowercased()):
                self.tags.otherTags.append(SimpleTag(
                    tag: extractedTag.rawTag,
                    contents: extractedTag.contents
                ))
            case nil:
                return listItem
            }

            return nil
        }

        mutating func visitDoxygenParameter(_ doxygenParam: DoxygenParameter) -> (any Markup)? {
            self.tags.parameters.append(Parameter(doxygenParam))
            return nil
        }

        mutating func visitDoxygenReturns(_ doxygenReturns: DoxygenReturns) -> (any Markup)? {
            self.tags.returns.append(Return(doxygenReturns))
            return nil
        }
    }

    func parse(markup: any Markup, upToSection lastSection: DocumentationMarkup.ParseSection)
        -> Result
    {
        var result = Result()

        var currentSection = DocumentationMarkup.ParseSection.abstract
        var discussionIndex: Int?

        for pair in markup.children.enumerated() {
            guard currentSection <= lastSection || currentSection == .end else { continue }

            let (index, child) = pair
            let isLastChild = index == (markup.childCount - 1)

            guard currentSection != .end else { continue }

            if currentSection == .abstract {
                if result.abstractSection == nil, let firstParagraph = child as? Paragraph {
                    result.abstractSection = AbstractSection(paragraph: firstParagraph)
                    continue
                } else if child is BlockDirective {
                    currentSection = .discussion
                } else if let _ = child as? HTMLBlock {
                    continue
                } else {
                    currentSection = .discussion
                }
            }

            let parseDiscussion: ([any Markup]) -> (
                discussion: DiscussionSection,
                tags: TaggedComponents
            ) = { children in
                var rewriter = Rewriter()
                let input = Document(children.compactMap { $0 as? (any BlockMarkup) })
                let remainder = (rewriter.visit(input) as? Document)
                let content: [any Markup] = remainder.map { Array($0.children) } ?? []
                return (
                    discussion: DiscussionSection(content: content),
                    tags: rewriter.tags
                )
            }

            if currentSection == .discussion {
                if discussionIndex == nil {
                    discussionIndex = index
                }
                guard let discussionIndex else { continue }

                if isLastChild {
                    let (
                        discussion,
                        tags
                    ) = parseDiscussion(markup.children(at: discussionIndex...index))
                    if !discussion.content.isEmpty {
                        result.discussionSection = discussion
                    }
                    result.tags = tags
                }
            }
        }

        return result
    }
}

// MARK: - Helpers restored from previous implementation

private extension ListItem {
    func extractTag() -> DocumentationMarkupParser.Rewriter.ExtractedTag? {
        guard childCount > 0,
              let paragraph = child(at: 0) as? Paragraph,
              let (name, nameRange, remainderOfFirstParagraph) = paragraph.inlineChildren
              .splitNameAndContent()
        else {
            return nil
        }

        return DocumentationMarkupParser.Rewriter.ExtractedTag(
            rawTag: name,
            tagRange: nameRange,
            contents: remainderOfFirstParagraph + children.dropFirst(),
            range: range
        )
    }

    func extractInnerTagOutline() -> [DocumentationMarkupParser.Rewriter.ExtractedTag] {
        var tags: [DocumentationMarkupParser.Rewriter.ExtractedTag] = []
        for child in children {
            guard let list = child as? UnorderedList else {
                continue
            }
            for child in list.children {
                guard let listItem = child as? ListItem,
                      let extractedTag = listItem.extractTag()
                else {
                    continue
                }
                tags.append(extractedTag)
            }
        }
        return tags
    }
}

private extension Sequence<InlineMarkup> {
    func splitNameAndContent()
        -> (name: String, nameRange: Markdown.SourceRange?, content: [any Markup])?
    {
        var iterator = makeIterator()
        guard let initialTextNode = iterator.next() as? Text else {
            return nil
        }

        let initialText = initialTextNode.string
        guard let colonIndex = initialText.firstIndex(of: ":") else {
            return nil
        }

        let nameStartIndex = initialText[...colonIndex]
            .firstIndex(where: { $0 != " " }) ?? initialText.startIndex
        let tagName = initialText[nameStartIndex..<colonIndex]
        guard !tagName.isEmpty else {
            return nil
        }
        let remainingInitialText = initialText.suffix(from: initialText.index(after: colonIndex))
            .drop { $0 == " " }

        var newInlineContent: [any InlineMarkup] = [Text(String(remainingInitialText))]
        while let more = iterator.next() {
            newInlineContent.append(more)
        }
        let newContent: [any Markup] = [Paragraph(newInlineContent)]

        let nameRange: Markdown.SourceRange? = initialTextNode.range.map { fullRange in
            var start = fullRange.lowerBound
            start.column += initialText.utf8.distance(
                from: initialText.startIndex,
                to: nameStartIndex
            )
            var end = start
            end.column += tagName.utf8.count
            return start..<end
        }

        return (String(tagName), nameRange, newContent)
    }
}

extension Sequence {
    func categorize<Result>(where matches: (Element) -> Result?)
        -> (matching: [Result], remainder: [Element])
    {
        var matching = [Result]()
        var remainder = [Element]()
        for element in self {
            if let matchingResult = matches(element) {
                matching.append(matchingResult)
            } else {
                remainder.append(element)
            }
        }
        return (matching, remainder)
    }
}
