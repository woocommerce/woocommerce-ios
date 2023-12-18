import SwiftUI
import Kingfisher
import struct Yosemite.WordPressTheme

/// View to display a list of WordPress themes
///
struct ThemesCarouselView: View {

    @ObservedObject private var viewModel: ThemesCarouselViewModel
    private let onSelectedTheme: (WordPressTheme) -> Void

    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

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
                            if let themeImageURL = getThemeImageURL(themeURL: theme.demoURI) {
                                themeImageCard(url: themeImageURL)
                            } else {
                                themeNameCard(name: theme.name)
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
            await viewModel.fetchThemes()
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
                    await viewModel.fetchThemes()
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

    var lastMessageCard: some View {
        ZStack {
            GeometryReader { geometry in
                ScrollView(.vertical) {
                    VStack {
                        Spacer()
                        Text(viewModel.mode.moreThemesTitleText)
                            .bold()
                            .secondaryBodyStyle()
                            .padding(.horizontal, Layout.contentPadding)

                        Spacer()
                            .frame(height: Layout.contentPadding)

                        Text(viewModel.mode.moreThemesSuggestionText)
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
    }
}

private extension ThemesCarouselView {
    private func getThemeImageURL(themeURL: String) -> URL? {
        let urlStr = "https://s0.wp.com/mshots/v1/\(themeURL)?demo=true/?w=1200&h=2400&vpw=400&vph=800"
        return URL(string: urlStr)
    }
}

struct ThemesCarouselView_Previews: PreviewProvider {
    static var previews: some View {
        ThemesCarouselView(viewModel: .init(mode: .themeSettings), onSelectedTheme: { _ in })
    }
}
