import Foundation
import Yosemite

/// View model for `ThemeSettingView`
///
final class ThemeSettingViewModel: ObservableObject {

    @Published private(set) var currentThemeName: String = ""
    @Published private(set) var loadingCurrentTheme: Bool = false

    private let siteID: Int64
    private let stores: StoresManager
    private(set) var carouselViewModel: ThemesCarouselViewModel
    private let themeInstaller: ThemeInstaller

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         themeInstaller: ThemeInstaller = DefaultThemeInstaller()) {
        self.siteID = siteID
        self.stores = stores
        self.themeInstaller = themeInstaller
        self.carouselViewModel = .init(siteID: siteID,
                                       mode: .themeSettings,
                                       stores: stores)

        configureCarouselViewModel()
        /// Attempt to install and activate any pending theme selection
        /// to show correct current theme information
        ///
        Task {
            await installPendingThemeIfNeeded()
        }
    }

    @MainActor
    func updateCurrentThemeName() async {
        loadingCurrentTheme = true
        let theme = await loadCurrentTheme()
        currentThemeName = theme?.name ?? ""
        loadingCurrentTheme = false
        carouselViewModel.updateCurrentTheme(id: theme?.id)
    }

    func updateCurrentTheme(_ theme: WordPressTheme) {
        currentThemeName = theme.name
        carouselViewModel.updateCurrentTheme(id: theme.id)
    }

    func trackViewAppear() {
        carouselViewModel.trackViewAppear()
    }
}

private extension ThemeSettingViewModel {
    func configureCarouselViewModel() {
        carouselViewModel.onReload = { [weak self] in
            guard let self else { return }
            Task {
                await self.updateCurrentThemeName()
            }
        }
    }

    /// Installs pending theme for the current site
    ///
    func installPendingThemeIfNeeded() async {
        do {
            try await themeInstaller.installPendingThemeIfNeeded(siteID: siteID)
        } catch {
            DDLogError("⛔️ Theme settings - Error installing pending theme: \(error)")
        }
    }

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
