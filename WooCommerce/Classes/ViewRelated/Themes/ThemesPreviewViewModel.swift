import Foundation
import Yosemite
import protocol WooFoundation.Analytics

/// ViewModel for ThemesPreviewView
///
final class ThemesPreviewViewModel: ObservableObject {
    @Published private(set) var pages: [WordPressPage]
    @Published private(set) var selectedPage: WordPressPage
    @Published private(set) var state: State = .pagesLoading

    @Published private(set) var installingTheme: Bool = false
    @Published var notice: Notice?

    // We need to append `demoModeSuffix` to prevent any activation / purchase header to appear on the theme demo.
    var selectedPageUrl: URL? {
        URL(string: selectedPage.link + Constants.demoModeSuffix)
    }

    let mode: ThemesCarouselViewModel.Mode
    let theme: WordPressTheme

    var primaryButtonTitle: String {
        let format = mode == .storeCreationProfiler ? Localization.startWithThemeButton : Localization.useThisThemeButton
        return String.localizedStringWithFormat(format, theme.name)
    }

    private let siteID: Int64
    private let stores: StoresManager
    private let themeInstaller: ThemeInstaller
    private let analytics: Analytics

    init(siteID: Int64,
         mode: ThemesCarouselViewModel.Mode,
         theme: WordPressTheme,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         themeInstaller: ThemeInstaller = DefaultThemeInstaller()) {
        self.siteID = siteID
        self.mode = mode
        self.theme = theme
        self.stores = stores
        self.analytics = analytics
        self.themeInstaller = themeInstaller

        // Pre-fill the selected Page with the home page.
        // The id is set as zero so to not clash with other pages' ids.
        let startingPage = WordPressPage(id: 0, title: Localization.homePage, link: theme.demoURI)
        self.selectedPage = startingPage
        pages = [startingPage]
    }

    @MainActor
    func fetchPages() async {
        do {
            // Append the list of pages to the existing home page value, since the API call result
            // does not include the home page.
            pages += try await loadPages()

            state = .pagesContent
        } catch {
            DDLogError("⛔️ Error loading pages: \(error)")
            state = .pagesLoadingError
        }
    }

    func setSelectedPage(page: WordPressPage) {
        selectedPage = page
        analytics.track(event: .Themes.previewPageSelected(page: page.title, url: page.link))
    }

    @MainActor
    func confirmThemeSelection() async throws {
        analytics.track(event: .Themes.startWithThemeButtonTapped(themeID: theme.id))

        /// We are skipping theme installation when in store creation flow because
        /// the theme can be installed only after the store is full ready. (Atomic transfer complete)
        ///
        /// The store creation profiler flow takes care of scheduling the selected theme for later installation.
        ///
        guard mode == .themeSettings else {
            return
        }

        installingTheme = true
        notice = nil
        do {
            try await themeInstaller.install(themeID: theme.id, siteID: siteID)
            installingTheme = false
        } catch {
            notice = Notice(title: Localization.themeInstallError,
                             feedbackType: .error)
            installingTheme = false
            throw error
        }
    }

    func trackViewAppear() {
        analytics.track(event: .Themes.previewScreenDisplayed())
    }

    func trackLayoutSwitch(layout: ThemesPreviewView.PreviewDevice) {
        analytics.track(event: .Themes.previewLayoutSelected(layout: layout))
    }
}

private extension ThemesPreviewViewModel {
    @MainActor
    func loadPages() async throws -> [WordPressPage] {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(WordPressSiteAction.fetchPageList(siteURL: theme.demoURI) { result in
                switch result {
                case .success(let pages):
                    continuation.resume(returning: pages)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
        }
    }
}

extension ThemesPreviewViewModel {
    private enum Constants {
        static let demoModeSuffix = "?demo"
    }

    enum State: Equatable {
        case pagesLoading
        case pagesLoadingError
        case pagesContent
    }

    private enum Localization {
        static let homePage = NSLocalizedString(
            "themesPreviewViewModel.homepageLabel",
            value: "Home",
            comment: "The label for the home page of a theme."
        )
        static let themeInstallError = NSLocalizedString(
            "themesPreviewViewModel.themeInstallError",
            value: "Theme installation failed. Please try again.",
            comment: "Message to convey that theme installation failed."
        )
        static let startWithThemeButton = NSLocalizedString(
            "themesPreviewViewModel.startWithThemeButton",
            value: "Start with %1$@",
            comment: "Button in theme preview screen to pick a theme. The placeholder is the theme name. " +
            "Reads like: Start with Tsubaki"
        )
        static let useThisThemeButton = NSLocalizedString(
            "themesPreviewViewModel.useThisThemeButton",
            value: "Use %1$@",
            comment: "Button in theme preview screen to pick a theme. The placeholder is the theme name. " +
            "Reads like: Use Tsubaki"
        )
    }
}
