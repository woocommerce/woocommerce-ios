import Foundation
import Yosemite

/// ViewModel for ThemesPreviewView
///
final class ThemesPreviewViewModel: ObservableObject {
    @Published private var pages: [WordPressPage] = []

    private let stores: StoresManager
    private let themeDemoURL: String

    init(themeDemoURL: String, stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
        self.themeDemoURL = themeDemoURL
    }

    @MainActor
    func fetchPages() async {
        do {
            pages = try await loadPages()
        } catch {
            DDLogError("⛔️ Error loading pages: \(error)")
        }
    }
}

private extension ThemesPreviewViewModel {
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
