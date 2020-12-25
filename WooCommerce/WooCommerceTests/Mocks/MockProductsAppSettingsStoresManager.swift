import Yosemite
@testable import WooCommerce

/// Allows mocking for Products feature switch in app settings.
///
final class MockProductsAppSettingsStoresManager: DefaultStoresManager {

    /// Indicates if products feature switch is enabled.
    ///
    var isProductsFeatureSwitchEnabled: Bool

    init(isProductsFeatureSwitchEnabled: Bool, sessionManager: SessionManager) {
        self.isProductsFeatureSwitchEnabled = isProductsFeatureSwitchEnabled
        super.init(sessionManager: sessionManager)
    }

    // MARK: - Overridden Methods

    override func dispatch(_ action: Action) {
        if let appSettingsAction = action as? AppSettingsAction {
            onAppSettingsAction(action: appSettingsAction)
        } else {
            super.dispatch(action)
        }
    }

    private func onAppSettingsAction(action: AppSettingsAction) {
        switch action {
        case .loadProductsFeatureSwitch(let onCompletion):
            onCompletion(isProductsFeatureSwitchEnabled)
        default:
            return
        }
    }
}
