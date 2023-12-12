import Foundation
import Yosemite

/// View model for `ThemeCarouselView`
///
final class ThemeCarouselViewModel: ObservableObject {

    @Published private(set) var themes: [WordPressTheme] = []
    @Published private(set) var fetchingThemes: Bool = false
    @Published private(set) var failedToFetchThemes: Bool = false

    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    @MainActor
    func fetchThemes() async {
        fetchingThemes = true
        failedToFetchThemes = false
        do {
            themes = try await loadSuggestedThemes()
        } catch {
            failedToFetchThemes = true
        }
        fetchingThemes = false
    }
}

private extension ThemeCarouselViewModel {
    @MainActor
    func loadSuggestedThemes() async throws -> [WordPressTheme] {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(WordPressThemeAction.loadSuggestedThemes { result in
                switch result {
                case .success(let themes):
                    continuation.resume(returning: themes)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
        }
    }
}
