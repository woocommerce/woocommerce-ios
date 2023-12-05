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

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.stores = stores
        self.analytics = analytics
    }

    @MainActor
    func updateCurrentThemeName() async {
        loadingCurrentTheme = true
        currentThemeName = await loadCurrentThemeName()
        loadingCurrentTheme = false
    }
}

private extension ThemeSettingViewModel {

    @MainActor
    func loadCurrentThemeName() async -> String {
        await withCheckedContinuation { continuation in
            stores.dispatch(WordPressThemeAction.loadCurrentTheme(siteID: siteID) { result in
                switch result {
                case .success(let theme):
                    continuation.resume(returning: theme.name)
                case .failure(let error):
                    DDLogError("⛔️ Error loading current theme: \(error)")
                    // TODO: #11291 - analytics
                    continuation.resume(returning: "")
                }
            })
        }
    }
}
