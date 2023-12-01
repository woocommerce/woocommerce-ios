import SwiftUI

final class ThemeSettingHostingController: UIHostingController<ThemeSettingView> {
    init(siteID: Int64) {
        super.init(rootView: ThemeSettingView())
    }

    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// View for selecting a new theme for the current site.
///
struct ThemeSettingView: View {
    var body: some View {
        NavigationView {
            Form {
                Section(Localization.currentSection) {
                    HStack {
                        Text(Localization.themeRow)
                            .bodyStyle()
                        Spacer()
                        Text("Tsubaki")
                            .secondaryBodyStyle()
                    }
                }

                Section(Localization.tryOtherLook) {
                    VStack {
                        // TODO: add slider here
                        Spacer()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancelButton) {
                        // TODO: dismiss view
                    }
                }
            }
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
        }
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
