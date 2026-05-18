import Foundation

extension String {
    static func assistantHumanizedToolToken(_ raw: String) -> String {
        let cleaned = raw.replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "/", with: " ")
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
    }
}
