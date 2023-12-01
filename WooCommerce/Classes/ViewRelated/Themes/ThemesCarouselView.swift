import SwiftUI
import Kingfisher


struct ThemesCarouselView: View {
    /// Tuple array containing theme name and theme Url string pair.
    let themesInfo: [(name: String, url: String)] = [
        (name: "Google", url: "google.com"),
        (name: "Facebook", url: "facebook.com"),
        (name: "WordPress", url: "wordpress.com"),
        (name: "Microsoft", url: "microsoft.com"),
        (name: "Amazon", url: "amazon.com"),
        (name: "Apple", url: "apple.com")
    ]

    /// The title of the message at the end of the carousel.
    let lastMessageHeading: String

    /// The content of the message at the end of the carousel.
    let lastMessageContent: String


    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack() {

                // Demo for correct state
                ForEach(themesInfo, id: \.name) { theme in
                    if let themeUrl = getThemeUrl(themeUrl: theme.url) {
                        ThemeImage(url: themeUrl)
                    } else {
                        ThemeName(name: theme.name)
                    }
                }

                // Demo for error state
                ThemeName(name: themesInfo[0].name)

                // Demo for last message content
                VStack {
                    Text(lastMessageHeading)
                        .bold()
                        .bodyStyle()
                        .padding(.horizontal, Layout.contentPadding)

                    Spacer()
                        .frame(height: Layout.contentPadding)

                    Text(lastMessageContent)
                        .subheadlineStyle()
                            .multilineTextAlignment(.center)
                        .padding(.horizontal, Layout.contentPadding)
                }.frame(
                    width: Layout.imageWidth * scale,
                    height: Layout.imageHeight * scale
                )
            }
        }
    }
}

private struct ThemeImage: View {
    let url: URL
    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {
        KFImage(url)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: Layout.imageWidth * scale, height: Layout.imageHeight * scale)
            .cornerRadius(Layout.cornerRadius)
            .shadow(radius: Layout.shadowRadius, x: 0, y: Layout.shadowYOffset)
            .padding(Layout.imagePadding)
    }
}

private struct ThemeName: View {
    let name: String

    var body: some View {
        VStack {
            Text(name)
        }
        .frame(width: Layout.imageWidth, height: Layout.imageHeight)
        .background(Color.withColorStudio(
            name: .wooCommercePurple,
            shade: .shade0))
        .cornerRadius(Layout.cornerRadius)
        .shadow(radius: Layout.shadowRadius, x: 0, y: Layout.shadowYOffset)
        .padding(Layout.imagePadding)
    }
}

private extension ThemesCarouselView {
    private func getThemeUrl(themeUrl: String) -> URL? {
        let urlStr = "https://s0.wp.com/mshots/v1/https://\(themeUrl)?demo=true/?w=1200&h=2400&vpw=400&vph=800"
        return URL(string: urlStr)
    }
}

private enum Layout {
    static let contentPadding: CGFloat = 16
    static let imagePadding: CGFloat = 8
    static let imageWidth: CGFloat = 250
    static let imageHeight: CGFloat = 500
    static let cornerRadius: CGFloat = 8
    static let shadowRadius: CGFloat = 2
    static let shadowYOffset: CGFloat = 3
}

struct ThemesCarouselView_Previews: PreviewProvider {
    static var previews: some View {
        ThemesCarouselView(
            lastMessageHeading: "Heading example",
            lastMessageContent: "Message content example here which can be long."
        )
    }
}
