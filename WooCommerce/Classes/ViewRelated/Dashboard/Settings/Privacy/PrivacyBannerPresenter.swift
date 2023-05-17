import Foundation
import UIKit
import WordPressUI

/// Type to handle the privacy banner presentation.
///
final class PrivacyBannerPresenter {

    /// User Defaults database
    ///
    private let defaults: UserDefaults

    init(defaults: UserDefaults = UserDefaults.standard) {
        self.defaults = defaults
    }

    /// Present the banner when the appropriate conditions are met.
    ///
    func presentIfNeeded(from viewController: UIViewController) {
        guard ServiceLocator.featureFlagService.isFeatureFlagEnabled(.privacyChoices) else {
            return
        }

        let countryCode = Locale.current.regionCode ?? "" // TODO: Switch for the real user country code.
        let useCase = PrivacyBannerPresentationUseCase(countryCode: countryCode, defaults: defaults)

        guard useCase.shouldShowPrivacyBanner() else {
            return
        }

        let privacyBanner = PrivacyBannerViewController(goToSettingsAction: {
            print("Go to settings tapped") // TODO: Navigate to settings
        }, saveAction: {
            print("Saved tapped") // TODO: perform network request
        })


        let bottomSheetViewController = BottomSheetViewController(childViewController: privacyBanner)
        bottomSheetViewController.show(from: viewController)
    }
}
