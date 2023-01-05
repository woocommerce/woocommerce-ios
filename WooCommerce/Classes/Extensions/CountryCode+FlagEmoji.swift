import Foundation

extension SiteAddress.CountryCode {
    /// Returns the flag emoji based on the country code if available.
    /// Reference: https://stackoverflow.com/a/30403199/9185596
    var flagEmoji: String? {
        // From en.wikipedia.org/wiki/Regional_Indicator_Symbol, the flags start at code point 0x1F1E6.
        // The offset for "A" is 65. 0x1F1E6 - 65 = 127397.
        let base: UInt32 = 127397
        var flagEmoji = ""
        for scalar in rawValue.uppercased().unicodeScalars {
            guard let flagEmojiScalar = UnicodeScalar(base + scalar.value) else {
                return nil
            }
            flagEmoji.unicodeScalars.append(flagEmojiScalar)
        }
        return flagEmoji
    }
}
