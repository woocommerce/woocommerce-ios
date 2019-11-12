import Yosemite

extension Product {
    var singleLineFullDescription: String? {
        guard let description = fullDescription else {
            return nil
        }
        return description.removedHTMLTags
    }
}
