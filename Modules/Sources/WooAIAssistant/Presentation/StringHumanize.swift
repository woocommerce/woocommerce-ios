import Foundation

extension String {

    /// Shared by tool pills and confirmation diff labels for consistent phrasing.
    static func assistantHumanizedToolToken(_ raw: String) -> String {
        let cleaned = raw.replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "/", with: " ")
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
    }

    /// Skips numeric / price / email tokens so currency and totals are left as-is.
    static func assistantHumanizedValue(_ value: String) -> String {
        guard !value.isEmpty else { return value }
        if value.contains(where: { $0.isNumber || $0 == "@" || $0 == "$" || $0 == "." }) {
            return value
        }
        let words = value.split(separator: " ").map { token -> String in
            let lower = token.lowercased()
            return lower.localizedCapitalized
        }
        return words.joined(separator: " ")
    }
}
