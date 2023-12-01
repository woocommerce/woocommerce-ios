import SwiftUI

/// View for selecting a new theme for the current site.
///
struct ThemeSettingView: View {
    var body: some View {
        Text("Hello, World!")
    }
}

private extension ThemeSettingView {
    enum Localization {
        static let title = NSLocalizedString(
            "themeSettingView.title",
            value: "Themes",
            comment: "Title for the theme settings screen"
        )

        static let currentSection = NSLocalizedString(
            "themeSettingView.currentSection",
            value: "Current",
            comment: "Title for the Current section on the theme settings screen"
        )

        static let themeRow = NSLocalizedString(
            "themeSettingView.themeRow",
            value: "Theme",
            comment: "Title for the Theme row on the theme settings screen"
        )

        static let tryOtherLook = NSLocalizedString(
            "themeSettingView.tryOtherLookLabel",
            value: "Try other new look",
            comment: "Label for the suggested theme section on the theme settings screen"
        )

        static let cancelButton = NSLocalizedString(
            "themeSettingView.cancelButton",
            value: "Cancel",
            comment: "Button to dismiss the theme settings screen"
        )
    }
}

struct ThemeSettingView_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            ThemeSettingView()
        }
    }
}
