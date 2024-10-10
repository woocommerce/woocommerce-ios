import Foundation
import UIKit


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

    /// A Boolean value indicating whether a string has characters.
    var isNotEmpty: Bool {
        return !isEmpty
    }

    /// Get quotation marks from Locale
    static var quotes: (String, String) {
        guard
            let bQuote = Locale.current.quotationBeginDelimiter,
            let eQuote = Locale.current.quotationEndDelimiter
        else { return ("\"", "\"") }

        return (bQuote, eQuote)
    }

    /// Puts quotation marks at the beginning and the end of the string
    var quoted: String {
        let (bQuote, eQuote) = String.quotes
        return bQuote + self + eQuote
    }

    /// Given an string made of tags separated by commas, returns an array with these tags
    ///
    func setOfTags() -> Set<String>? {
        guard !self.isEmpty else {
            return [String()]
        }

        let arrayOfTags = self.components(separatedBy: ",").map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })

        guard !arrayOfTags.isEmpty else {
            return nil
        }

        return Set(arrayOfTags)
    }

    func removingSuffix(_ suffix: String) -> String {
        guard hasSuffix(suffix) else {
            return self
        }

        return String(self.dropLast(suffix.count))
    }
}

#if !os(watchOS)
extension String {
    /// Sends the string to the general pasteboard and triggers a success haptic.
    /// If the string is nil, nothing is sent to the pasteboard.
    ///
    /// - Parameter includeTrailingNewline: If true, inserts a trailing newline; defaults to true
    ///
    func sendToPasteboard(includeTrailingNewline: Bool = true) {
        guard self.isEmpty == false else {
            return
        }

        var text: String = self
        if includeTrailingNewline {
            text += "\n"
        }

        UIPasteboard.general.string = text
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
#endif
