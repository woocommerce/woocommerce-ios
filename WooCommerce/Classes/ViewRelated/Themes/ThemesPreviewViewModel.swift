import Foundation
import Yosemite

/// ViewModel for ThemesPreviewView
///
final class ThemesPreviewViewModel: ObservableObject {
    @Published private var pages: [WordPressPage] = []

    private let stores: StoresManager
    private let siteURL: String

    init(stores: StoresManager = ServiceLocator.stores,
         siteURL: String) {
        self.stores = stores
        self.siteURL = siteURL
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
            stores.dispatch(WordPressSiteAction.fetchPageList(siteURL: siteURL) { result in
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
