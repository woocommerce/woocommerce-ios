import Foundation


/// Locale: Woo Methods
///
extension Locale {

    /// Returns the System's Preferred Language. Defaults to English
    ///
    static var preferredLanguage: String {
        return Locale.preferredLanguages.first ?? "en"
    }
}
