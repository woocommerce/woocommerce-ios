import Foundation
import Yosemite
import protocol WooFoundation.Analytics

final class PackageStarToggleService {
    private let siteID: Int64
    private let stores: StoresManager
    private let analytics: Analytics

    @Published var notice: Notice?

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.stores = stores
        self.analytics = analytics
    }

    func toggle(packageID: String,
                carrierID: String,
                isStarred: Bool,
                onRollback: @escaping () -> Void) {
        let action: WooShippingAction
        if isStarred {
            let predefined = WooShippingPredefinedSavedOption(id: carrierID, predefinedPackageIDs: [packageID])
            action = .createPackage(siteID: siteID, customPackage: nil, predefinedOption: predefined) { [weak self] result in
                guard let self else { return }
                if case .failure(let error) = result {
                    DDLogError("⛔️ Error starring package: \(error)")
                    onRollback()
                    notice = Notice(title: Localization.savingFailure,
                                   feedbackType: .error,
                                   actionTitle: Localization.retry,
                                   actionHandler: { [weak self] in
                        self?.toggle(packageID: packageID, carrierID: carrierID, isStarred: isStarred, onRollback: onRollback)
                    })
                    analytics.track(event: .WooShipping.packageSelectionStep(state: .savingFailed, error: error))
                } else {
                    analytics.track(event: .WooShipping.packageSelectionStep(state: .savingSuccess))
                }
            }
        } else {
            action = .deletePackage(siteID: siteID,
                                    packageID: packageID,
                                    packageType: .predefined,
                                    completion: { [weak self] result in
                guard let self else { return }
                if case .failure(let error) = result {
                    DDLogError("⛔️ Error unstarring package: \(error)")
                    onRollback()
                    notice = Notice(title: Localization.removingFailure,
                                   feedbackType: .error,
                                   actionTitle: Localization.retry,
                                   actionHandler: { [weak self] in
                        self?.toggle(packageID: packageID, carrierID: carrierID, isStarred: isStarred, onRollback: onRollback)
                    })
                    analytics.track(event: .WooShipping.packageSelectionStep(state: .removingFailed, error: error))
                } else {
                    analytics.track(event: .WooShipping.packageSelectionStep(state: .removingSuccess))
                }
            })
        }
        stores.dispatch(action)
    }
}

private extension PackageStarToggleService {
    enum Localization {
        static let savingFailure = NSLocalizedString(
            "wooShipping.packageStarToggle.savingFailure",
            value: "Unable to save package",
            comment: "Message on a notice when saving a package fails in the shipping creation flow"
        )
        static let removingFailure = NSLocalizedString(
            "wooShipping.packageStarToggle.removingFailure",
            value: "Unable to remove package",
            comment: "Message on a notice when removing a package fails in the shipping creation flow"
        )
        static let retry = NSLocalizedString(
            "wooShipping.packageStarToggle.retry",
            value: "Retry",
            comment: "Button to retry saving/removing a package in the shipping creation flow"
        )
    }
}
