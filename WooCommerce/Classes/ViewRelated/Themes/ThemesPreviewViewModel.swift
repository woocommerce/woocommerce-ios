import Foundation
import Yosemite

/// ViewModel for ThemesPreviewView
///
final class ThemesPreviewViewModel: ObservableObject {
    @Published private(set) var pages: [WordPressPage] = []
    @Published private(set) var selectedPage: WordPressPage
    @Published private(set) var state: State = .pagesLoading

    @Published private(set) var installingTheme: Bool = false
    @Published var notice: Notice?

    let mode: ThemesCarouselViewModel.Mode
    let theme: WordPressTheme

    private let siteID: Int64
    private let stores: StoresManager
    private let themeInstaller: ThemeInstaller

    init(siteID: Int64,
         mode: ThemesCarouselViewModel.Mode,
         theme: WordPressTheme,
         stores: StoresManager = ServiceLocator.stores,
         themeInstaller: ThemeInstaller = DefaultThemeInstaller()) {
        self.siteID = siteID
        self.mode = mode
        self.theme = theme
        self.stores = stores
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
            // do not include the home page.
            pages += try await loadPages()
            state = .pagesContent
        } catch {
            DDLogError("⛔️ Error loading pages: \(error)")
            state = .pagesLoadingError
        }
    }

    func setSelectedPage(page: WordPressPage) {
        selectedPage = page
    }

    @MainActor
    func confirmThemeSelection() async throws {
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
    }
}
