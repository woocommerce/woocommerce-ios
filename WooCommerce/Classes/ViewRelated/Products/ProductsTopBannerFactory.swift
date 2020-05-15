import UIKit
import Yosemite

struct ProductsTopBannerFactory {
    /// Creates a products tab top banner asynchronously based on the app settings.
    /// - Parameters:
    ///   - expandedStateChangeHandler: called when the top banner expanded state changes.
    ///   - onCompletion: called when the view controller is created and ready for display.
    static func topBanner(expandedStateChangeHandler: @escaping () -> Void,
                          onCompletion: @escaping (TopBannerView) -> Void) {
        let action = AppSettingsAction.loadProductsFeatureSwitch { isEditProductsRelease2Enabled in
            let title = isEditProductsRelease2Enabled ? Strings.titleWhenEditProductsRelease2IsEnabled: Strings.titleWhenEditProductsRelease2IsDisabled
            let infoText = isEditProductsRelease2Enabled ? Strings.infoWhenEditProductsRelease2IsEnabled: Strings.infoWhenEditProductsRelease2IsDisabled
            let viewModel = TopBannerViewModel(title: title,
                                               infoText: infoText,
                                               icon: .workInProgressBanner,
                                               expandedStateChangeHandler: expandedStateChangeHandler)
            let topBannerView = TopBannerView(viewModel: viewModel)
            topBannerView.translatesAutoresizingMaskIntoConstraints = false
            onCompletion(topBannerView)
        }
        ServiceLocator.stores.dispatch(action)
    }
}

private extension ProductsTopBannerFactory {
    enum Strings {
        static let titleWhenEditProductsRelease2IsEnabled =
            NSLocalizedString("New editing options available",
                              comment: "The title of the Work In Progress top banner on the Products tab when the Products release 2 feature switch is on.")
        static let titleWhenEditProductsRelease2IsDisabled =
            NSLocalizedString("Limited editing available",
                              comment: "The title of the Work In Progress top banner on the Products tab when the Products release 2 feature switch is off.")
        static let infoWhenEditProductsRelease2IsEnabled =
            NSLocalizedString(
                "We've added more editing functionalities to products. You can now update images, see previews and sort, filter & share products!",
                              comment: "The info of the Work In Progress top banner on the Products tab when the Products release 2 feature switch is on.")
        static let infoWhenEditProductsRelease2IsDisabled =
            NSLocalizedString("We've added editing functionality to simple products. Keep an eye out for more options soon!",
                              comment: "The info of the Work In Progress top banner on the Products tab when the Products release 2 feature switch is off.")
    }
}
