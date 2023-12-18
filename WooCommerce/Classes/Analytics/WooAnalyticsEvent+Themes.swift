import Foundation

extension WooAnalyticsEvent {

    enum Themes {
        private enum Key: String {
            case source
            case theme
            case layout
            case page
            case pageURL = "page_url"
        }

        enum Source: String {
            case profiler
            case settings
        }

        /// Tracks when the theme picker screen is displayed
        static func pickerScreenDisplayed(source: Source) -> WooAnalyticsEvent {
            .init(statName: .themePickerScreenDisplayed, properties: [
                Key.source.rawValue: source.rawValue
            ])
        }
    }
}
