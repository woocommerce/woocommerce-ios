import Foundation
import HTMLParser

/// Internal DOM-based verifier; callers use the stateless façade on `CookieNonceAuthenticationEndpoints`.
struct WordPressLoginHTMLVerifier {
    struct LoginForm {
        let action: String?
    }

    private let html: String
    private let root: ElementNode

    init(html: String) {
        self.html = html
        root = HTMLParser().parse(html)
    }

    func verifiedLoginForm() -> LoginForm? {
        guard hasSafeStructure else {
            return nil
        }
        let forms = renderedElements(in: root).compactMap { element -> LoginForm? in
            guard element.name.lowercased() == "form" else {
                return nil
            }
            return verifiedLoginForm(in: element)
        }
        guard forms.count == 1 else {
            return nil
        }
        return forms.first
    }

    func verifiedLoginForm(in form: ElementNode) -> LoginForm? {
        guard form.value(of: "id") == "loginform", form.value(of: "name") == "loginform",
              form.value(of: "method")?.lowercased() == "post" else {
            return nil
        }
        let inputs = formInputs(in: form).filter(\.isEligible)
        let loginInputs = inputs.filter { $0.value(of: "name") == "log" }
        let passwordInputs = inputs.filter { $0.value(of: "name") == "pwd" }
        guard loginInputs.count == 1, passwordInputs.count == 1,
              let loginInput = loginInputs.first, let passwordInput = passwordInputs.first,
              loginInput.isCredential(name: "log", id: "user_login", type: "text"),
              passwordInput.isCredential(name: "pwd", id: "user_pass", type: "password") else {
            return nil
        }
        return LoginForm(action: form.value(of: "action")?.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var isAuthenticatedDashboard: Bool {
        let elements = renderedElements(in: root)
        let dashboardBody = elements.contains { element in
            guard element.name.lowercased() == "body" else {
                return false
            }
            let classes = Set((element.value(of: "class") ?? "").split(whereSeparator: \.isWhitespace).map { $0.lowercased() })
            return classes.isSuperset(of: ["wp-admin", "index-php"])
        }
        return dashboardBody && elements.contains { $0.value(of: "id") == "dashboard-widgets-wrap" }
    }

    var loginErrorMessage: String? {
        guard let error = renderedElements(in: root).first(where: { $0.value(of: "id") == "login_error" }) else {
            return nil
        }
        let message = renderedText(in: error).split(whereSeparator: \.isWhitespace).joined(separator: " ")
        return message.isEmpty ? nil : message
    }
}

private extension WordPressLoginHTMLVerifier {
    static let nonRendered = Set(["script", "style", "template", "textarea", "title", "iframe", "noembed", "noframes", "xmp", "svg", "math"])
    static let nonRenderedPattern = "script|style|template|textarea|title|iframe|noembed|noframes|xmp|svg|math"

    var hasSafeStructure: Bool {
        guard let withoutComments = removing("<!--[\\s\\S]*?-->", from: html),
              let stripped = removing("<(\(Self.nonRenderedPattern))\\b[^>]*>[\\s\\S]*?</\\1\\s*>", from: withoutComments),
              let leftovers = matches("<!--|-->|<\\s*/?\\s*(\(Self.nonRenderedPattern))\\b", in: stripped),
              let formTags = matches("<\\s*/?\\s*form\\b", in: stripped),
              let formRegions = matches("<form\\b[^>]*>[\\s\\S]*?</form\\s*>", in: stripped),
              leftovers == 0, formTags == 2 * formRegions else {
            return false
        }
        return true
    }

    func removing(_ pattern: String, from value: String) -> String? {
        guard let expression = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        return expression.stringByReplacingMatches(in: value, range: NSRange(value.startIndex..., in: value), withTemplate: "")
    }

    func matches(_ pattern: String, in value: String) -> Int? {
        guard let expression = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        return expression.numberOfMatches(in: value, range: NSRange(value.startIndex..., in: value))
    }

    func renderedElements(in root: ElementNode) -> [ElementNode] {
        root.children.flatMap { renderedElements(in: $0) }
    }

    func renderedElements(in node: Node) -> [ElementNode] {
        guard let element = node as? ElementNode,
              Self.nonRendered.contains(element.name.lowercased()) == false else {
            return []
        }
        return [element] + element.children.flatMap { renderedElements(in: $0) }
    }

    func formInputs(in form: ElementNode) -> [ElementNode] {
        form.children.flatMap { node -> [ElementNode] in
            guard let element = node as? ElementNode, Self.nonRendered.contains(element.name.lowercased()) == false,
                  element.name.lowercased() != "form" else {
                return []
            }
            return (element.name.lowercased() == "input" ? [element] : []) + formInputs(in: element)
        }
    }

    func renderedText(in node: Node) -> String {
        if let text = node as? TextNode {
            return text.contents
        }
        guard let element = node as? ElementNode,
              Self.nonRendered.contains(element.name.lowercased()) == false,
              element.name.lowercased() != "a" else {
            return ""
        }
        return element.children.map(renderedText(in:)).joined(separator: " ")
    }
}

private extension ElementNode {
    func value(of attributeName: String) -> String? {
        attribute(named: attributeName)?.value.toString()
    }

    var isEligible: Bool {
        attribute(named: "disabled") == nil && attribute(named: "form") == nil
    }

    func isCredential(name: String, id: String, type: String) -> Bool {
        value(of: "name") == name && value(of: "id") == id && value(of: "type")?.lowercased() == type
    }
}
