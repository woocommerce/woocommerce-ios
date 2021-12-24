import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// View model for `ShippingLabelPaymentMethods`.
///
final class ShippingLabelPaymentMethodsViewModel: ObservableObject {

    /// Indicates if the view model is updating the remote account settings or fetching remote account settings
    ///
    @Published var isUpdating: Bool = false

    /// Shipping Label account settings from the remote API
    ///
    private var accountSettings: ShippingLabelAccountSettings

    @Published var selectedPaymentMethodID: Int64
    @Published var isEmailReceiptsEnabled: Bool

    /// List of payment methods available to choose from
    ///
    var paymentMethods: [ShippingLabelPaymentMethod] {
        accountSettings.paymentMethods
    }

    var storeOwnerUsername: String {
        accountSettings.storeOwnerUsername
    }

    var storeOwnerDisplayName: String {
        accountSettings.storeOwnerDisplayName
    }

    var storeOwnerWPcomUsername: String {
        accountSettings.storeOwnerWpcomUsername
    }

    var storeOwnerWPcomEmail: String {
        accountSettings.storeOwnerWpcomEmail
    }

    /// Whether the user has permission to edit the payment method.
    /// Currently this is only true for the store owner.
    ///
    var canEditPaymentMethod: Bool {
        accountSettings.canManagePayments
    }

    /// Whether the user has permission to edit non-payment settings.
    /// Currently this is always true (hard-coded on the backend).
    ///
    var canEditNonpaymentSettings: Bool {
        accountSettings.canEditSettings
    }

    /// The URL path that will trigger the exit from the webview for adding a new payment method
    ///
    let fetchPaymentMethodURLPath = "me/purchases/payment-methods"

    init(accountSettings: ShippingLabelAccountSettings) {
        self.accountSettings = accountSettings
        self.selectedPaymentMethodID = accountSettings.selectedPaymentMethodID
        self.isEmailReceiptsEnabled = accountSettings.isEmailReceiptsEnabled
    }

    func didSelectPaymentMethod(withID paymentMethodID: Int64) {
        selectedPaymentMethodID = paymentMethodID
    }

    /// Return true if the done button should be enabled (if any shipping label account settings have changed)
    ///
    func isDoneButtonEnabled() -> Bool {
        let isPaymentMethodChanged = selectedPaymentMethodID != accountSettings.selectedPaymentMethodID
        let isEmailReceiptsChanged = isEmailReceiptsEnabled != accountSettings.isEmailReceiptsEnabled
        return ( isPaymentMethodChanged || isEmailReceiptsChanged ) && !isUpdating && accountSettings.paymentMethods.isNotEmpty
    }
}

// MARK: - API Requests
//
extension ShippingLabelPaymentMethodsViewModel {

    /// Syncs account settings specific to shipping labels, such as the last selected package and payment methods.
    ///
    func syncShippingLabelAccountSettings() {
        isUpdating = true
        let action = ShippingLabelAction.synchronizeShippingLabelAccountSettings(siteID: accountSettings.siteID) { [weak self] result in
            guard let self = self else { return }

            self.isUpdating = false
            switch result {
            case .success(let value):
                self.accountSettings = value
                self.selectedPaymentMethodID = value.selectedPaymentMethodID
            case .failure:
                DDLogError("⛔️ Error synchronizing shipping label account settings")
            }
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Updates remote shipping label account settings
    ///
    func updateShippingLabelAccountSettings(onCompletion: @escaping ((ShippingLabelAccountSettings) -> Void)) {
        isUpdating = true
        let newSettings = accountSettings.copy(selectedPaymentMethodID: selectedPaymentMethodID,
                                        isEmailReceiptsEnabled: isEmailReceiptsEnabled)

        let action = ShippingLabelAction.updateShippingLabelAccountSettings(siteID: accountSettings.siteID, settings: newSettings) { [weak self] result in
            self?.isUpdating = false

            switch result {
            case .success:
                onCompletion(newSettings)
            case .failure:
                ServiceLocator.noticePresenter.enqueue(notice: .init(title: Localization.updateSettingsError, feedbackType: .error))
                DDLogError("⛔️ Error updating shipping label account settings")
            }
        }
        ServiceLocator.stores.dispatch(action)
    }
}

// MARK: - Localization
//
private extension ShippingLabelPaymentMethodsViewModel {
    enum Localization {
        static let updateSettingsError = NSLocalizedString("Unable to save changes to the payment method",
                                                           comment: "Content of error presented when Update Shipping Label Account Settings Action Failed. "
                                                            + "It reads: Unable to save changes to the payment method.")
    }
}

// MARK: - Methods for rendering a SwiftUI Preview
//
extension ShippingLabelPaymentMethodsViewModel {

    static let samplePaymentMethodID: Int64 = 11743265

    static func sampleAccountSettings(withPermissions: Bool = true) -> ShippingLabelAccountSettings {
        return ShippingLabelAccountSettings(siteID: 1234,
                                            canManagePayments: withPermissions,
                                            canEditSettings: withPermissions,
                                            storeOwnerDisplayName: "Display Name",
                                            storeOwnerUsername: "admin",
                                            storeOwnerWpcomUsername: "username",
                                            storeOwnerWpcomEmail: "user@example.com",
                                            paymentMethods: samplePaymentMethods(),
                                            selectedPaymentMethodID: 11743265,
                                            isEmailReceiptsEnabled: true,
                                            paperSize: .label,
                                            lastSelectedPackageID: "small_flat_box")
    }

    static func samplePaymentMethods() -> [ShippingLabelPaymentMethod] {
        let paymentMethod1 = ShippingLabelPaymentMethod(paymentMethodID: 11743265,
                                                       name: "Marie Claire",
                                                       cardType: .visa,
                                                       cardDigits: "4242",
                                                       expiry: DateFormatter.Defaults.yearMonthDayDateFormatter.date(from: "2030-12-31"))

        let paymentMethod2 = ShippingLabelPaymentMethod(paymentMethodID: 12345678,
                                                        name: "Marie Claire",
                                                        cardType: .mastercard,
                                                        cardDigits: "4343",
                                                        expiry: DateFormatter.Defaults.yearMonthDayDateFormatter.date(from: "2030-01-31"))

        return [paymentMethod1, paymentMethod2]
    }

}
