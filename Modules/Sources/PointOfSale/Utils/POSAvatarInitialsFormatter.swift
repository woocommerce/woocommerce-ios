import Foundation

struct POSAvatarInitialsFormatter {
    static func initials(from name: String?) -> String? {
        guard let name, !name.isEmpty else { return nil }
        let components = name.split(separator: " ")
        guard let first = components.first else { return nil }
        if components.count >= 2 {
            return String(first.prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(first.prefix(1)).uppercased()
    }
}
