import SwiftUI
import Kingfisher
import struct Yosemite.WordPressTheme

/// View to display a list of WordPress themes
///
struct ThemesCarouselView: View {

    @ObservedObject private var viewModel: ThemesCarouselViewModel

    @State private var selectedTheme: WordPressTheme? = nil

    private let onSelectedTheme: (WordPressTheme) -> Void

    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    let imageErrorAttributedString: NSAttributedString = {
        let font: UIFont = .subheadline

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let tapHereText = NSAttributedString(string: Localization.tapHere, attributes: [.foregroundColor: UIColor.accent.cgColor, .font: font])
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraph,
            .foregroundColor: UIColor.secondaryLabel.cgColor
        ]
        let message = NSMutableAttributedString(string: Localization.errorLoadingImage, attributes: attributes)
        message.replaceFirstOccurrence(of: "%@", with: tapHereText)

        return message
    }()

    init(viewModel: ThemesCarouselViewModel, onSelectedTheme: @escaping (WordPressTheme) -> Void) {
        self.viewModel = viewModel
        self.onSelectedTheme = onSelectedTheme
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                loadingView

            case .content(let themes):
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack() {

                        // Theme list
                        ForEach(themes) { theme in
                            Button(action: {
                                viewModel.trackThemeSelected(theme)
                                selectedTheme = theme
                            }) {
                                if let themeImageURL = theme.themeThumbnailURL {
                                    themeImageCard(url: themeImageURL)
                                } else {
                                    themeNameCard(name: theme.name)
                                }
                            }
                        }

                        // Message at the end of the carousel
                        lastMessageCard
                    }
                }

            case .error:
                errorView
            }
        }
        .task {
            await viewModel.fetchThemes(isReload: false)
        }
        .sheet(item: $selectedTheme, content: { theme in
            ThemesPreviewView(
                viewModel: .init(siteID: viewModel.siteID,
                                 mode: viewModel.mode,
                                 theme: theme),
                onSelectedTheme: {
                    onSelectedTheme(theme)
                }
            )
        })
        .onAppear {
            viewModel.trackViewAppear()
        }
    }
}

private extension ThemesCarouselView {
    var loadingView: some View {
        VStack {
            Spacer()
            ActivityIndicator(isAnimating: .constant(true), style: .medium)
            Text(Localization.loadingThemes)
                .secondaryBodyStyle()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: Layout.imageHeight)
    }

    var errorView: some View {
        VStack(spacing: Layout.contentPadding) {
            Spacer()
            Text(Localization.errorLoadingThemes)
                .secondaryBodyStyle()
            Button {
                Task {
                    await viewModel.fetchThemes(isReload: true)
                }
            } label: {
                Label(Localization.retry, systemImage: "arrow.clockwise")
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: Layout.imageHeight)
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
        VStack(spacing: Layout.contentPadding) {
            Text(name)
                .fontWeight(.semibold)
                .foregroundColor(.init(uiColor: .text))
                .subheadlineStyle()
            AttributedText(imageErrorAttributedString)
        }
        .padding(Layout.contentPadding)
        .frame(width: Layout.imageWidth, height: Layout.imageHeight)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(Layout.cornerRadius)
        .shadow(radius: Layout.shadowRadius, x: 0, y: Layout.shadowYOffset)
        .padding(Layout.imagePadding)
    }

    var lastMessageCard: some View {
        ZStack {
            GeometryReader { geometry in
                ScrollView(.vertical) {
                    VStack {
                        Spacer()
                        Text(Localization.lookingForMore)
                            .bold()
                            .secondaryBodyStyle()
                            .padding(.horizontal, Layout.contentPadding)

                        Spacer()
                            .frame(height: Layout.contentPadding)

                        Text(Localization.findInWooThemeStore)
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

    private enum Localization {
        static let loadingThemes = NSLocalizedString(
            "themesCarouselView.loading",
            value: "Loading themes...",
            comment: "Text indicating the loading state in the themes carousel view"
        )
        static let errorLoadingThemes = NSLocalizedString(
            "themesCarouselView.error",
            value: "Failed to load themes.",
            comment: "Text indicating the error state in the themes carousel view"
        )
        static let retry = NSLocalizedString(
            "themesCarouselView.retry",
            value: "Retry",
            comment: "Button to reload themes in the themes carousel view"
        )
        static let lookingForMore = NSLocalizedString(
            "themesCarouselView.lastMessageHeading",
            value: "Looking for more?",
            comment: "The heading of the message shown at the end of the themes carousel view"
        )

        static let findInWooThemeStore = NSLocalizedString(
            "themesCarouselView.lastMessageContent",
            value: "You can find your perfect theme in the WooCommerce Theme Store.",
            comment: "The content of the message shown at the end of the themes carousel view"
        )

        static let errorLoadingImage = NSLocalizedString(
            "themesCarouselView.thumbnailError",
            value: "Sorry, it seems there is an issue with the template loading. " +
            "Please %@ for a live demo",
            comment: "Error message for when theme image cannot be loaded on the themes carousel view. " +
            "%@ is the place holder for 'tap here'. " +
            "Reads like: Sorry, it seems there is an issue with the template loading. " +
            "Please tap here for a live demo"
        )

        static let tapHere = NSLocalizedString(
            "themesCarouselView.thumbnailError.tapHere",
            value: "tap here",
            comment: "Action to show live demo on the themes carousel view"
        )
    }
}

struct ThemesCarouselView_Previews: PreviewProvider {
    static var previews: some View {
        ThemesCarouselView(viewModel: .init(siteID: 123, mode: .themeSettings), onSelectedTheme: { _ in })
    }
}
