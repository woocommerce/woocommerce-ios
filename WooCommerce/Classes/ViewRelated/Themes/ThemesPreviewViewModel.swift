import Foundation
import Yosemite

/// ViewModel for ThemesPreviewView
///
final class ThemesPreviewViewModel: ObservableObject {
    @Published private(set) var pages: [WordPressPage] = []
    @Published private(set) var selectedPage: WordPressPage
    @Published private(set) var state: State = .pagesLoading

    private let stores: StoresManager
    private let themeDemoURL: String

    init(themeDemoURL: String, stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
        self.themeDemoURL = themeDemoURL

        // Pre-fill the selected Page with the home page.
        // The id is set as zero so to not clash with other pages' ids.
        let startingPage = WordPressPage(id: 0, title: Localization.homePage, link: themeDemoURL)
        self.selectedPage = startingPage
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
}

private extension ThemesPreviewViewModel {
    @MainActor
    func loadPages() async throws -> [WordPressPage] {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(WordPressSiteAction.fetchPageList(siteURL: themeDemoURL) { result in
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
    }
}
