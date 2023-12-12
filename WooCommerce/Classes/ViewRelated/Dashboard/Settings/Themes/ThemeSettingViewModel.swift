import Foundation
import Yosemite

/// View model for `ThemeSettingView`
/// 
final class ThemeSettingViewModel: ObservableObject {

    @Published private(set) var currentThemeName: String = ""
    @Published private(set) var loadingCurrentTheme: Bool = false

    private let siteID: Int64
    private let stores: StoresManager
    private let analytics: Analytics
    private(set) var carouselViewModel: ThemesCarouselViewModel

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.stores = stores
        self.analytics = analytics
        self.carouselViewModel = .init(stores: stores)
    }

    @MainActor
    func updateCurrentThemeName() async {
        loadingCurrentTheme = true
        let theme = await loadCurrentTheme()
        currentThemeName = theme?.name ?? ""
        loadingCurrentTheme = false
        await carouselViewModel.fetchThemes(currentThemeID: theme?.id)
    }
}

private extension ThemeSettingViewModel {

    @MainActor
    func loadCurrentTheme() async -> WordPressTheme? {
        await withCheckedContinuation { continuation in
            stores.dispatch(WordPressThemeAction.loadCurrentTheme(siteID: siteID) { result in
                switch result {
                case .success(let theme):
                    continuation.resume(returning: theme)
                case .failure(let error):
                    DDLogError("⛔️ Error loading current theme: \(error)")
                    // TODO: #11291 - analytics
                    continuation.resume(returning: nil)
                }
            })
        }
    }
}
