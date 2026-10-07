import Foundation
import HTMLParser

/// A short, masked excerpt for support diagnostics. This does not evaluate stylesheets.
enum UnexpectedResponseExcerpt {
    static func make(_ body: String) -> String? {
        let text: String
        if let json = try? JSONSerialization.jsonObject(with: Data(body.utf8), options: .fragmentsAllowed) {
            guard let error = json as? [String: Any], let code = error["code"] as? String,
                  let message = error["message"] as? String else { return nil }
            text = "\(code) | \(visibleText(in: HTMLParser().parse(message)))"
        } else {
            // A DOM parser keeps quoted '>' characters inside attributes and never includes attribute values as text.
            let root = HTMLParser().parse(body)
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
