import Foundation

/// Locale: Woo Methods
///
public extension Locale {

    /// Returns the locale identifier in `xx_XX` format (e.g. `en_US`),
    /// constructed from the language code and region code.
    ///
    /// Falls back to just the language code if the region is unavailable,
    /// or `nil` if even the language code cannot be determined.
    ///
    var languageRegionIdentifier: String? {
        guard let languageCode = language.languageCode?.identifier else {
            return nil
        }
        guard let regionCode = region?.identifier else {
            return languageCode
        }
        return "\(languageCode)_\(regionCode)"
    }
}
