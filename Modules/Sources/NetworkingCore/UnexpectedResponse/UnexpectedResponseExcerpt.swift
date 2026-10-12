import Foundation
import HTMLParser

/// A short, masked excerpt for support diagnostics. This does not evaluate stylesheets.
enum UnexpectedResponseExcerpt {
    static func make(_ body: String) -> String? {
        let text: String
        if let json = try? JSONSerialization.jsonObject(with: Data(body.utf8), options: .fragmentsAllowed) {
            guard let error = json as? [String: Any], let code = error["code"] as? String,
                  let message = error["message"] as? String else { return nil }
            text = "\(code) | \(visibleText(in: parse(message)))"
        } else {
            // A DOM parser keeps quoted '>' characters inside attributes and never includes attribute values as text.
            let root = parse(body)
            let title = pageTitle(in: root).map(UnexpectedResponseMetadata.sanitize) ?? ""
            // Plugin/debug output can be followed by a store payload, including malformed JSON.
            let page = UnexpectedResponseMetadata.sanitize(String(visibleText(in: root).prefix { $0 != "{" && $0 != "[" }))
            text = title.isEmpty || page.hasPrefix(title) ? page : page.isEmpty ? title : "\(title) | \(page)"
        }
        // Mask the complete text before cutting it, including secrets that cross the truncation boundary.
        let cleaned = UnexpectedResponseMetadata.sanitize(text)
        guard !cleaned.isEmpty else { return nil }
        return cleaned.count > 300 ? String(cleaned.prefix(299)) + "…" : cleaned
    }

    private static let nonRendered = Set(["script", "style", "noscript", "template", "svg", "math", "iframe",
                                          "textarea", "select", "input", "noembed", "noframes", "xmp"])

    private static let voidElements = Set(["area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "source", "track", "wbr"])
    private static let rawTextElements = Set(["script", "style", "textarea", "title", "iframe", "noembed", "noframes", "xmp"])

    private struct Tag {
        let name: String
        let attributes: String
        let range: Range<String.Index>
        let isClosing: Bool
        let isEmpty: Bool

        var isHidden: Bool {
            guard attributes.range(of: #"\b(?:hidden|aria-hidden|style)\b"#,
                                   options: [.regularExpression, .caseInsensitive]) != nil else { return false }
            // Parse attributes on a neutral element so libxml's implicit closing rules cannot change their scope.
            guard let element = HTMLParser().parse("<div\(attributes)></div>").children.first as? ElementNode else { return false }
            return UnexpectedResponseExcerpt.isHidden(element)
        }
    }

    private static func parse(_ html: String) -> Node {
        // libxml repairs unclosed <p>/<li> elements, potentially moving private text outside a hidden subtree.
        // Remove private regions using source boundaries first; an unclosed region drops the remaining source.
        var visible = ""
        var index = html.startIndex
        var hiddenName: String?
        var depth = 0
        while let start = html.range(of: #"<[A-Za-z/!?]"#, options: .regularExpression, range: index..<html.endIndex)?.lowerBound {
            if hiddenName == nil { visible += html[index..<start] }
            guard let tag = tag(in: html, at: start) else {
                return HTMLParser().parse(visible)
            }
            if let hiddenElementName = hiddenName {
                if tag.name == hiddenElementName && !tag.isEmpty {
                    depth += tag.isClosing ? -1 : 1
                    if depth == 0 { hiddenName = nil }
                }
            } else if !tag.isClosing && (nonRendered.contains(tag.name) || tag.isHidden) {
                visible += " "
                if !tag.isEmpty {
                    hiddenName = tag.name
                    depth = 1
                }
            } else {
                visible += html[tag.range]
            }
            index = tag.range.upperBound
        }
        if hiddenName == nil { visible += html[index...] }
        return HTMLParser().parse(visible)
    }

    private static func tag(in html: String, at start: String.Index) -> Tag? {
        if html[start...].hasPrefix("<!--") {
            let end = html.range(of: "-->", range: start..<html.endIndex)?.upperBound ?? html.endIndex
            return Tag(name: "", attributes: "", range: start..<end, isClosing: false, isEmpty: true)
        }
        let nameStart = html.index(after: start)
        let isClosing = html[nameStart] == "/"
        let searchStart = isClosing ? html.index(after: nameStart) : nameStart
        let nameRange = html.range(of: #"^[A-Za-z][A-Za-z0-9-]*"#, options: .regularExpression, range: searchStart..<html.endIndex)
        let name = nameRange.map { String(html[$0]).lowercased() } ?? ""
        let attributesStart = nameRange?.upperBound ?? searchStart
        var quote: Character?
        var index = attributesStart
        while index < html.endIndex {
            let character = html[index]
            if let currentQuote = quote {
                if character == currentQuote { quote = nil }
            } else if character == "\"" || character == "'" {
                quote = character
            } else if character == ">" {
                let attributes = String(html[attributesStart..<index])
                var end = html.index(after: index)
                var isEmpty = name.isEmpty || voidElements.contains(name) || attributes.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("/")
                if !isClosing && rawTextElements.contains(name) {
                    end = html.range(of: "</" + name + #"\s*>"#, options: [.regularExpression, .caseInsensitive],
                                     range: end..<html.endIndex)?.upperBound ?? html.endIndex
                    isEmpty = true
                }
                return Tag(name: name, attributes: attributes, range: start..<end, isClosing: isClosing, isEmpty: isEmpty)
            }
            index = html.index(after: index)
        }
        return nil
    }

    private static func pageTitle(in node: Node) -> String? {
        guard let element = node as? ElementNode, !isHidden(element), !nonRendered.contains(element.name.lowercased()) else { return nil }
        if element.name.lowercased() == "title" {
            return element.children.map(visibleText(in:)).joined(separator: " ")
        }
        return element.children.lazy.compactMap(pageTitle(in:)).first
    }

    private static func visibleText(in node: Node) -> String {
        if let text = node as? TextNode { return text.contents }
        guard let element = node as? ElementNode, !isHidden(element),
              !nonRendered.contains(element.name.lowercased()), !["head", "title"].contains(element.name.lowercased()) else { return "" }
        return element.children.map(visibleText(in:)).joined(separator: " ")
    }

    private static func isHidden(_ element: ElementNode) -> Bool {
        if element.attribute(named: "hidden") != nil || element.attribute(named: "aria-hidden")?.value.toString()?.lowercased() == "true" {
            return true
        }
        let style = element.attribute(named: "style")?.value.toString() ?? ""
        return style.range(of: #"(?i)(?:^|;)\s*(?:display\s*:\s*none|visibility\s*:\s*(?:hidden|collapse))\s*(?:!important\s*)?(?:;|$)"#,
                           options: .regularExpression) != nil
    }
}
