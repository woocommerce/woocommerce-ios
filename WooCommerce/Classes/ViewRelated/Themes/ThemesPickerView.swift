import SwiftUI
import Kingfisher

struct ThemesPickerView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {
        let urls = [
            "google.com",
            "facebook.com",
            "microsoft.com",
            "wordpress.com",
            "amazon.com",
            "apple.com"
        ]

        ScrollView {
            VStack(alignment: .leading) {
                Spacer()
                    .frame(height: 40)

                // Title label.
                Text(Localization.chooseThemeHeading)
                    .bold()
                    .largeTitleStyle()
                    .padding(.horizontal, Layout.contentPadding)

                Spacer()
                    .frame(height: 16)

                // Subtitle label.
                Text(Localization.chooseThemeSubtitle)
                    .subheadlineStyle()
                    .padding(.horizontal, Layout.contentPadding)

                Spacer()
                    .frame(height: 40)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack() {
                        ForEach(urls, id: \.self) { url in
                            if let themeURL = getThemeUrl(themeUrl: url) {
                                KFImage(themeURL)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: Layout.imageWidth * scale, height: Layout.imageHeight * scale)
                                    .cornerRadius(Layout.cornerRadius)
                                    .shadow(radius: Layout.shadowRadius, x: 0, y: 3)
                                    .padding(.init(
                                        top: Layout.imageVerticalPadding,
                                        leading: Layout.imageHorizontalPadding,
                                        bottom: Layout.imageVerticalPadding,
                                        trailing: Layout.imageHorizontalPadding)
                                    )

                            }
                        }
                    }
                }

                Spacer()
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

private extension ThemesPickerView {
    private func getThemeUrl(themeUrl: String) -> URL? {
        let urlStr = "https://s0.wp.com/mshots/v1/https://\(themeUrl)?demo=true/?w=1200&h=2400&vpw=400&vph=800"
        return URL(string: urlStr)
    }
}

struct ThemesPickerView_Previews: PreviewProvider {
    static var previews: some View {
        ThemesPickerView()
    }
}

private extension ThemesPickerView {
    private enum Layout {
        static let contentPadding: CGFloat = 16
        static let imageHorizontalPadding: CGFloat = 8
        static let imageVerticalPadding: CGFloat = 8
        static let imageWidth: CGFloat = 225
        static let imageHeight: CGFloat = 450
        static let cornerRadius: CGFloat = 8
        static let shadowRadius: CGFloat = 2
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

}
