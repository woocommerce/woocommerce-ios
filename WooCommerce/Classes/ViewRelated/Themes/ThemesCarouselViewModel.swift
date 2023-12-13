import Foundation
import Yosemite

/// View model for `ThemesCarouselView`
///
final class ThemesCarouselViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case error
        case content(themes: [WordPressTheme])
    }

    enum Mode: Equatable {
        case themeSettings
        case storeCreationProfiler
    }

    @Published private(set) var state: State = .loading
    @Published private var themes: [WordPressTheme] = []
    @Published private var currentThemeID: String?

    private let mode: Mode
    private let stores: StoresManager

    init(mode: Mode, stores: StoresManager = ServiceLocator.stores) {
        self.mode = mode
        self.stores = stores
        observeThemeListAndCurrentTheme()
    }

    @MainActor
    func fetchThemes() async {
        state = .loading
        do {
            themes = try await loadSuggestedThemes()
        } catch {
            DDLogError("⛔️ Error loading suggested themes: \(error)")
            state = .error
        }
    }

    func updateCurrentTheme(id: String?) {
        currentThemeID = id
    }
}

private extension ThemesCarouselViewModel {
    func observeThemeListAndCurrentTheme() {
        $themes.combineLatest($currentThemeID.dropFirst())
            .map { themes, currentThemeID in
                let filteredThemes = themes.filter { $0.id != currentThemeID }
                return State.content(themes: filteredThemes)
            }
            .assign(to: &$state)
    }

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
