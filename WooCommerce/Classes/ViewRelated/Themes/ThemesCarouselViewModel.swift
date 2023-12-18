import Foundation
import Yosemite

/// View model for `ThemesCarouselView`
///
final class ThemesCarouselViewModel: ObservableObject {

    @Published private(set) var state: State = .loading
    @Published private var themes: [WordPressTheme] = []
    @Published private var currentThemeID: String?

    let mode: Mode
    private let stores: StoresManager

    /// Closure to be triggered when the theme list is reloaded.
    var onReload: (() -> Void)?

    init(mode: Mode,
         stores: StoresManager = ServiceLocator.stores) {
        self.mode = mode
        self.stores = stores
        // current theme is only required for theme settings mode.
        if mode == .themeSettings {
            waitForCurrentThemeAndFinishLoading()
        }
    }

    @MainActor
    func fetchThemes(isReload: Bool) async {
        if isReload {
            onReload?()
        }
        state = .loading
        do {
            themes = try await loadSuggestedThemes()
            /// Only update state immediately for the profiler flow.
            /// The theme setting flow requires waiting for the current theme ID.
            if mode == .storeCreationProfiler {
                state = .content(themes: themes)
            }
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
    func waitForCurrentThemeAndFinishLoading() {
        $themes.combineLatest($currentThemeID.dropFirst())
            .map { themes, currentThemeID -> State in
                let filteredThemes = themes.filter { $0.id != currentThemeID }
                return filteredThemes.isEmpty ? .error : .content(themes: filteredThemes)
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

extension ThemesCarouselViewModel {
    enum State: Equatable {
        case loading
        case error
        case content(themes: [WordPressTheme])
    }

    enum Mode: Equatable {
        case themeSettings
        case storeCreationProfiler
    }
}
