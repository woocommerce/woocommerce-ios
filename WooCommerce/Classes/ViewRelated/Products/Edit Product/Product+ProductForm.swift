import Yosemite

extension Product {
    /// Returns the full description without the HTML tags and leading/trailing white spaces and new lines.
    var trimmedFullDescription: String? {
        guard let description = fullDescription else {
            return nil
        }
        return description.removedHTMLTags.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
