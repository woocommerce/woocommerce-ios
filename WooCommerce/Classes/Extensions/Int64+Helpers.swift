import Foundation

extension Int64 {
    /// Present the amount for byte count
    ///
    var byteCountRepresentable: String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .memory)
    }

    /// Byte count in English, e.g. `12.40 GB`.
    ///
    /// `ByteCountFormatter` translates its units and offers no locale setting, so it cannot be used for values
    /// that leave the device: support tickets and status reports are read by Happiness Engineers rather than by
    /// the merchant, and must not follow the device's language.
    ///
    var englishByteCountRepresentable: String {
        let sizeAbbreviations = ["bytes", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"]
        var sizeAbbreviationsIndex = 0
        var capacity = Double(self)

        while capacity >= 1024 && sizeAbbreviationsIndex < sizeAbbreviations.count - 1 {
            capacity /= 1024
            sizeAbbreviationsIndex += 1
        }

        return String(format: "%4.2f", capacity) + " " + sizeAbbreviations[sizeAbbreviationsIndex]
    }
}
