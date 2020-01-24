import Foundation


/// String: Helper Methods
///
extension String {

    /// Helper method to provide the singular or plural (formatted) version of a
    /// string based on a count.
    ///
    /// - Parameters:
    ///   - count: Number of 'things' in the string
    ///   - singular: Singular version of localized string — used if `count` is 1
    ///   - plural: Plural version of localized string — used if `count` is greater than 1
    /// - Returns: Singular or plural version of string based on `count` param
    ///
    /// NOTE: String params _must_ include `%ld` placeholder (count will be placed there).
    ///
    static func pluralize(_ count: Int, singular: String, plural: String) -> String {
        if count == 1 {
            return String.localizedStringWithFormat(singular, count)
        } else {
            return String.localizedStringWithFormat(plural, count)
        }
    }

    /// Helper method to provide the singular or plural (formatted) version of a
    /// string based on a count.
    ///
    /// - Parameters:
    ///   - count: Number of 'things' in the string
    ///   - singular: Singular version of localized string — used if `count` is 1
    ///   - plural: Plural version of localized string — used if `count` is greater than 1
    /// - Returns: Singular or plural version of string based on `count` param
    ///
    /// NOTE: String params _must_ include `%@` placeholder (count will be placed there).
    ///
    static func pluralize(_ count: Decimal, singular: String, plural: String) -> String {
        let stringCount = NSDecimalNumber(decimal: count).stringValue

        if count > 0 && count < 1 || count == 1 {
            return String.localizedStringWithFormat(singular, stringCount)
        } else {
            return String.localizedStringWithFormat(plural, stringCount)
        }
    }

    /// Helper method to remove the last newline character in a given string.
    ///
    /// - Parameters:
    ///   - string: the string to format
    /// - Returns: a string with the newline character removed, if the
    ///            newline character is the last character in the string.
    ///
    static func stripLastNewline(in string: String) -> String {
        var newText = string
        let lastChar = newText.suffix(1)

        let newline = String(lastChar)
        if newline == "\n" {
            newText.removeSuffix(newline)
        }

        return newText
    }

    /// A Boolean value indicating whether a string is not empty.
    var isNotEmpty: Bool {
        return !isEmpty
    }
}
