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
            case storeCreation = "store_creation"
            case settings
        }

        /// Tracked when the theme picker screen is displayed
        static func pickerScreenDisplayed(source: Source) -> WooAnalyticsEvent {
            .init(statName: .themePickerScreenDisplayed, properties: [
                Key.source.rawValue: source.rawValue
            ])
        }

        /// Tracked when a theme screenshot is tapped on the theme picker screen
        static func themeSelected(id: String) -> WooAnalyticsEvent {
            .init(statName: .themePickerThemeSelected, properties: [
                Key.theme.rawValue: id
            ])
        }

        /// Tracked when the theme preview screen is displayed
        static func previewScreenDisplayed() -> WooAnalyticsEvent {
            .init(statName: .themePreviewScreenDisplayed, properties: [:])
        }

        /// Tracked when the user selected a layout to be previewed
        static func previewLayoutSelected(layout: ThemesPreviewView.PreviewDevice) -> WooAnalyticsEvent {
            .init(statName: .themePreviewLayoutSelected, properties: [
                Key.layout.rawValue: layout.rawValue
            ])
        }

        /// Tracked when the user selected a page to be previewed
        static func previewPageSelected(page: String, url: String) -> WooAnalyticsEvent {
            .init(statName: .themePreviewPageSelected, properties: [
                Key.page.rawValue: page,
                Key.pageURL.rawValue: url
            ])
        }

        /// Tracked when the “Start with the theme” button on preview screen is tapped
        static func startWithThemeButtonTapped(themeID: String) -> WooAnalyticsEvent {
            .init(statName: .themePreviewStartWithThemeButtonTapped, properties: [
                Key.theme.rawValue: themeID
            ])
        }

        /// Tracked when app finishes installing a theme on the site
        static func themeInstallationCompleted(themeID: String) -> WooAnalyticsEvent {
            .init(statName: .themeInstallationCompleted, properties: [
                Key.theme.rawValue: themeID
            ])
        }

        /// Tracked when app failed to install a theme on the site
        static func themeInstallationFailed(themeID: String, error: Error) -> WooAnalyticsEvent {
            .init(statName: .themeInstallationFailed, properties: [
                Key.theme.rawValue: themeID
            ], error: error)
        }
     }
}
