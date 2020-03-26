import Yosemite

extension Product {
    /// Returns the full description without the HTML tags and leading/trailing white spaces and new lines.
    var trimmedFullDescription: String? {
        guard let description = fullDescription else {
            return nil
        }
        return description.removedHTMLTags.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Returns the brief description (short description) without the HTML tags and leading/trailing white spaces and new lines.
    var trimmedBriefDescription: String? {
        guard let description = briefDescription else {
            return nil
        }
        return description.removedHTMLTags.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Returns a coma separated string with each category names.
    /// Uses `ListFormatter` if available
    var categoriesDescription: String {
        let categoriesNames = categories.map { $0.name }
        if #available(iOS 13.0, *) {
            return ListFormatter.localizedString(byJoining: categoriesNames)
        } else {
            return categoriesNames.joined(separator: ",")
        }
    }
}
