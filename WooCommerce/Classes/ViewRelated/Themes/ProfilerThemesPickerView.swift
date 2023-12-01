import SwiftUI
import Kingfisher

struct ProfilerThemesPickerView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {

        ScrollView {
            VStack(alignment: .leading) {
                Spacer()
                    .frame(height: Layout.contentVerticalSpacing)

                Text(Localization.chooseThemeHeading)
                    .bold()
                    .largeTitleStyle()
                    .padding(.horizontal, Layout.contentPadding)

                Spacer()
                    .frame(height: Layout.contentPadding)

                Text(Localization.chooseThemeSubtitle)
                    .subheadlineStyle()
                    .padding(.horizontal, Layout.contentPadding)

                Spacer()
                    .frame(height: Layout.contentVerticalSpacing)

                ThemesCarouselView(
                    lastMessageHeading: Localization.lastMessageHeading,
                    lastMessageContent: Localization.lastMessageContent
                )

                Spacer()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(Localization.skipButtonTitle) {
                    // TODO: Setup toolbar.
                }
            }
        }
        // Disables large title to avoid a large gap below the navigation bar.
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProfilerThemesPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ProfilerThemesPickerView()
    }
}

private extension ProfilerThemesPickerView {
    private enum Layout {
        static let contentPadding: CGFloat = 16
        static let contentVerticalSpacing: CGFloat = 40
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

        static let lastMessageHeading = NSLocalizedString(
            "ThemesPickerView.lastMessageHeading",
            value: "Looking for more?",
            comment: "The heading of the message shown at the end of carousel"
        )

        static let lastMessageContent = NSLocalizedString(
            "ThemesPickerView.lastMessageContent",
            value: "Once your store is set up, find your perfect theme in the WooCommerce Theme Store.",
            comment: "The content of the message shown at the end of carousel"
        )
    }
}
