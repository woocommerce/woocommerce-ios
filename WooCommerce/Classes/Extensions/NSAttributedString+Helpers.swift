import Foundation

/// NSAttributedString: Helper Methods
///
extension NSAttributedString {

    /// Returns the receiver as a NSString instance.
    ///
    var foundationString: NSString {
        return string as NSString
    }

    /// Returns a copy of the receiver, with the Leading + Trailing newlines trimmed.
    ///
    func trimNewlines() -> NSAttributedString {
        guard let trimmed = mutableCopy() as? NSMutableAttributedString else {
            return self
        }

        let characterSet = CharacterSet.newlines

        // Trim: Leading
        var range = trimmed.foundationString.rangeOfCharacter(from: characterSet)

        while range.length != 0 && range.location == 0 {
            trimmed.replaceCharacters(in: range, with: String())
            range = trimmed.foundationString.rangeOfCharacter(from: characterSet)
        }

        // Trim Trailing
        range = trimmed.foundationString.rangeOfCharacter(from: characterSet, options: .backwards)

        while range.length != 0 && NSMaxRange(range) == trimmed.length {
            trimmed.replaceCharacters(in: range, with: String())
            range = trimmed.foundationString.rangeOfCharacter(from: characterSet, options: .backwards)
        }

        return trimmed
    }
}
