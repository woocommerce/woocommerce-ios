import Foundation
import UIKit


/// String: Helper Methods
///
extension String {
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
