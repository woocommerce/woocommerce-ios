import Foundation
import Yosemite

/// ViewModel for ThemesPreviewView
///
final class ThemesPreviewViewModel: ObservableObject {
    @Published private var pages: [WordPressPage] = []
    @Published private(set) var state: State = .pagesLoading

    private let stores: StoresManager
    private let themeDemoURL: String

    init(themeDemoURL: String, stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
        self.themeDemoURL = themeDemoURL
    }

    @MainActor
    func fetchPages() async {
        // If the theme demo is using "*.wordpress.com", then the fetching will not work.
        // This also indicates that the theme does not have Woo-specific pages. In this case,
        // We decide to only show the home page.
        if themeDemoURL.contains("wordpress.com") {
            state = .pagesContent(pages: [WordPressPage(id: 0, title: Localization.homePage, link: themeDemoURL)])
        } else {
            do {
                pages = try await loadPages()
                state = .pagesContent(pages: pages)
            } catch {
                DDLogError("⛔️ Error loading pages: \(error)")
                state = .pagesLoadingError
            }
        }
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
        case pagesContent(pages: [WordPressPage])
    }

    private enum Localization {
        static let homePage = NSLocalizedString(
            "themesPreviewViewModel.homepageLabel",
            value: "Home",
            comment: "The label for the home page of a theme."
        )
    }
}
