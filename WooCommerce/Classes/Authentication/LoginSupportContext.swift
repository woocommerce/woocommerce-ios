import Foundation

/// An immutable snapshot of the failed login attempt, independent of the restored authentication session.
struct LoginSupportContext {
    let failure: LoginUnexpectedResponseFailure
    let flow: LoginUnexpectedResponseFailure.LoginFlow
    let siteURL: String?

    init(failure: LoginUnexpectedResponseFailure, flow: LoginUnexpectedResponseFailure.LoginFlow, siteURL: String?) {
        self.failure = failure
        self.flow = flow
        var components = siteURL.flatMap { URLComponents(string: $0) }
        components?.user = nil
        components?.password = nil
        components?.query = nil
        components?.fragment = nil
        self.siteURL = components.flatMap { value in
            guard ["http", "https"].contains(value.scheme?.lowercased() ?? ""), value.host?.isEmpty == false else { return nil }
            return value.url?.absoluteString
        }
    }

    var initialMessage: String {
        var message = String(format: Localization.message, siteURL ?? Localization.unknown, failure.step.rawValue,
                             flow.rawValue, failure.kind.rawValue, failure.statusCode.map(String.init) ?? Localization.unknown)
        if let diagnostics = failure.diagnostics {
            message += "\n" + String(format: Localization.metadata, diagnostics.request, diagnostics.contentType ?? Localization.unknown)
            if let excerpt = diagnostics.excerpt {
                message += "\n" + String(format: Localization.excerpt, excerpt)
            }
        }
        return message
    }

    private enum Localization {
        static let message = NSLocalizedString(
            "com.woocommerce.login.supportContext.message",
            value: "I couldn't log in to my store. Please help me troubleshoot this unexpected response.\n\n" +
                "Site: %1$@\nLogin step: %2$@\nLogin flow: %3$@\nFailure kind: %4$@\nHTTP status: %5$@",
            comment: "Automatic user message opening support chat after an unexpected login response; placeholders contain diagnostics")
        static let metadata = NSLocalizedString(
            "com.woocommerce.login.supportContext.metadata", value: "Request: %1$@\nContent type: %2$@",
            comment: "Request and content type diagnostic details in the automatic login support message")
        static let excerpt = NSLocalizedString(
            "com.woocommerce.login.supportContext.excerpt", value: "Response excerpt: %1$@",
            comment: "Sanitized response excerpt in the automatic login support message")
        static let unknown = NSLocalizedString(
            "com.woocommerce.login.supportContext.unknown", value: "Unknown",
            comment: "Unavailable diagnostic value in the automatic login support message")
    }
}
