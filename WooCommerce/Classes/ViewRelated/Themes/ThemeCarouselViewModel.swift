import Foundation
import Yosemite

/// View model for `ThemeCarouselView`
///
final class ThemeCarouselViewModel: ObservableObject {
    enum State {
        case loading
        case error
        case content(themes: [WordPressTheme])
    }

    @Published private(set) var state: State = .loading

    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    @MainActor
    func fetchThemes() async {
        state = .loading
        do {
            let themes = try await loadSuggestedThemes()
            state = .content(themes: themes)
        } catch {
            DDLogError("⛔️ Error loading suggested themes: \(error)")
            state = .error
        }
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
