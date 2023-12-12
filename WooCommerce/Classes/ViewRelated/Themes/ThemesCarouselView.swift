import SwiftUI
import Kingfisher
import struct Yosemite.WordPressTheme

/// View to display a list of WordPress themes
///
struct ThemesCarouselView: View {

    @ObservedObject private var viewModel: ThemeCarouselViewModel

    /// The title of the message at the end of the carousel.
    private let lastMessageHeading: String

    /// The content of the message at the end of the carousel.
    private let lastMessageContent: String


    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    init(viewModel: ThemeCarouselViewModel, lastMessageHeading: String, lastMessageContent: String) {
        self.viewModel = viewModel
        self.lastMessageHeading = lastMessageHeading
        self.lastMessageContent = lastMessageContent
    }

    var body: some View {
        VStack {
            loadingView
                .renderedIf(viewModel.fetchingThemes)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack() {
                    
                    // Theme list
                    ForEach(viewModel.themes) { theme in
                        if let themeUrl = getThemeUrl(themeUrl: theme.demoURI) {
                            themeImageCard(url: themeUrl)
                        } else {
                            themeNameCard(name: theme.name)
                        }
                    }
                    
                    // Message at the end of the carousel
                    lastMessageCard(heading: lastMessageHeading, message: lastMessageContent)
                }
            }
            .renderedIf(viewModel.themes.isNotEmpty)
        }
        .task {
            await viewModel.fetchThemes()
        }
    }
}

private extension ThemesCarouselView {
    var loadingView: some View {
        VStack {
            Spacer()
            ActivityIndicator(isAnimating: .constant(true), style: .medium)
            Text("Loading themes...")
                .secondaryBodyStyle()
            Spacer()
        }
        .frame(width: Layout.imageWidth, height: Layout.imageHeight)
    }

    func themeImageCard(url: URL) -> some View {
        KFImage(url)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: Layout.imageWidth, height: Layout.imageHeight)
            .cornerRadius(Layout.cornerRadius)
            .shadow(radius: Layout.shadowRadius, x: 0, y: Layout.shadowYOffset)
            .padding(Layout.imagePadding)
    }

    func themeNameCard(name: String) -> some View {
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

    func lastMessageCard(heading: String, message: String) -> some View {
        ZStack {
            GeometryReader { geometry in
                ScrollView(.vertical) {
                    VStack {
                        Spacer()
                        Text(lastMessageHeading)
                            .bold()
                            .secondaryBodyStyle()
                            .padding(.horizontal, Layout.contentPadding)

                        Spacer()
                            .frame(height: Layout.contentPadding)

                        Text(lastMessageContent)
                            .foregroundColor(Color(.secondaryLabel))
                            .subheadlineStyle()
                                .multilineTextAlignment(.center)
                            .padding(.horizontal, Layout.contentPadding)
                        Spacer()
                    }
                    .frame(width: geometry.size.width)
                    .frame(minHeight: geometry.size.height)
                }
            }
        }
        .frame(width: Layout.imageWidth, height: Layout.imageHeight)
    }
}

private extension ThemesCarouselView {
    private enum Layout {
        static let contentPadding: CGFloat = 16
        static let imagePadding: CGFloat = 8
        static let imageWidth: CGFloat = 250
        static let imageHeight: CGFloat = 500
        static let cornerRadius: CGFloat = 8
        static let shadowRadius: CGFloat = 2
        static let shadowYOffset: CGFloat = 3
    }
}

// TODO: This extension is temporary for UI preview purposes and can be deleted once this View is used with `WordPressTheme` items.
// In actual use, the screenshot URL is available from `WordPressTheme.themeThumbnailURL`
private extension ThemesCarouselView {
    private func getThemeUrl(themeUrl: String) -> URL? {
        let urlStr = "https://s0.wp.com/mshots/v1/https://\(themeUrl)?demo=true/?w=1200&h=2400&vpw=400&vph=800"
        return URL(string: urlStr)
    }
}

struct ThemesCarouselView_Previews: PreviewProvider {
    static var previews: some View {
        ThemesCarouselView(
            viewModel: .init(),
            lastMessageHeading: "Heading example",
            lastMessageContent: "Message content example here which can be pretty long if needed."
        )
    }
}
