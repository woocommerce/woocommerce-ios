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
    private let analytics: Analytics

    init(mode: Mode,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.mode = mode
        self.stores = stores
        self.analytics = analytics
        // current theme is only required for theme settings mode.
        if mode == .themeSettings {
            waitForCurrentThemeAndFinishLoading()
        }
    }

    @MainActor
    func fetchThemes() async {
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

    func trackViewAppear(source: WooAnalyticsEvent.Themes.Source) {
        analytics.track(event: .Themes.pickerScreenDisplayed(source: source))
    }
}

private extension ThemesCarouselViewModel {
    func waitForCurrentThemeAndFinishLoading() {
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

extension ThemesCarouselViewModel {
    enum State: Equatable {
        case loading
        case error
        case content(themes: [WordPressTheme])
    }

    enum Mode: Equatable {
        case themeSettings
        case storeCreationProfiler

        var moreThemesSuggestionText: String {
            switch self {
            case .themeSettings:
                return Localization.moreOnSettingsScreen
            case .storeCreationProfiler:
                return Localization.moreOnProfiler
            }
        }

        var moreThemesTitleText: String {
            Localization.lookingForMore
        }

        private enum Localization {
            static let lookingForMore = NSLocalizedString(
                "themesCarouselViewModel.lastMessageHeading",
                value: "Looking for more?",
                comment: "The heading of the message shown at the end of the carousel on the WordPress theme list"
            )

            static let moreOnSettingsScreen = NSLocalizedString(
                "themesCarouselViewModel.themeSetting.lastMessageContent",
                value: "Find your perfect theme in the WooCommerce Theme Store.",
                comment: "The content of the message shown at the end of the carousel on the theme settings screen"
            )

            static let moreOnProfiler = NSLocalizedString(
                "themesCarouselViewModel.profiler.lastMessageContent",
                value: "Once your store is set up, find your perfect theme in the WooCommerce Theme Store.",
                comment: "The content of the message shown at the end of carousel in the store creation profiler flow"
            )
        }
    }
}
