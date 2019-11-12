import Yosemite

extension String {
    func HTMLTagsRemoved() -> String {
        let string = replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
        return string
    }
}

extension Product {
    var singleLineFullDescription: String? {
        guard let description = fullDescription else {
            return nil
        }
        return description.HTMLTagsRemoved()
    }
}
