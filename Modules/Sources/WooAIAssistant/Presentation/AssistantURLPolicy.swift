import Foundation

/// Allowlist applied to URLs the AI Assistant tries to open.
///
/// Tool result strings can be attacker-controlled (guest order names,
/// customer notes, reviews). Markdown rendering turns those into tappable
/// links, so we filter at the renderer layer rather than trusting the
/// system prompt to keep URLs safe.
enum AssistantURLPolicy {
    static let allowedSchemes: Set<String> = ["http", "https"]

    static func allows(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return allowedSchemes.contains(scheme)
    }
}
