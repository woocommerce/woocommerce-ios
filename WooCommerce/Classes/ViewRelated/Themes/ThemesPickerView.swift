import SwiftUI

struct ThemesPickerView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {

                // Title label.
                Text(Localization.chooseThemeHeading)
                    .headlineStyle()

                // Subtitle label.
                Text(Localization.chooseThemeSubtitle)
                    .foregroundColor(Color(.secondaryLabel))
                    .bodyStyle()
            }

        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(Localization.skipButtonTitle) {
                    // todo
                }
            }
        }
        // Disables large title to avoid a large gap below the navigation bar.
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ThemesCarouselView_Previews: PreviewProvider {
    static var previews: some View {
        ThemesPickerView()
    }
}

private enum Localization {
    static let skipButtonTitle = NSLocalizedString(
        "ThemesPickerView.skipButtonTitle",
        value: "Skip",
        comment: "Title of the button to skip theme carousel screen."
    )

    static let chooseThemeHeading = NSLocalizedString(
    "ThemesPickerView.chooseThemeHeading",
    value: "Choose a theme",
    comment: "Main heading on the theme carousel screen."
    )

    static let chooseThemeSubtitle = NSLocalizedString(
    "ThemesPickerView.chooseThemeSubtitle",
    value: "You can always change it later in the settings.",
    comment: "Subtitle on the theme carousel screen."
    )
}
