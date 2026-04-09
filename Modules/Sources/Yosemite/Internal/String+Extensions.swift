import Foundation

extension String {

    private static let slugSafeCharacters = CharacterSet(charactersIn: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-")

    var slugified: String? {
        guard let latin = self.applyingTransform(StringTransform("Any-Latin; Latin-ASCII; Lower;"), reverse: false) else {
            return nil
        }

        let urlComponents = latin.components(separatedBy: String.slugSafeCharacters.inverted)
        let result = urlComponents.filter { !$0.isEmpty }.joined(separator: "-")

        guard !result.isEmpty else {
            return nil
        }

        return result
    }

}
