import Foundation

/// String: Helper Methods
///
public extension String {

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

    /// A Boolean value indicating whether a string has characters.
    var isNotEmpty: Bool {
        return !isEmpty
    }
}

#if !os(watchOS)
import UIKit

public extension String {
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
