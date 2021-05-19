import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// View model for `ShippingLabelPaymentMethods`.
///
final class ShippingLabelPaymentMethodsViewModel: ObservableObject {

    @Published private(set) var accountSettings: ShippingLabelAccountSettings
    @Published private(set) var paymentMethods: [ShippingLabelPaymentMethod]
    var selectedPaymentMethod: ShippingLabelPaymentMethod?
    var isEmailReceiptsEnabled: Bool

    init(accountSettings: ShippingLabelAccountSettings,
         selectedPaymentMethod: ShippingLabelPaymentMethod) {
        self.accountSettings = accountSettings
        self.paymentMethods = accountSettings.paymentMethods
        self.isEmailReceiptsEnabled = accountSettings.isEmailReceiptsEnabled
        self.selectedPaymentMethod = selectedPaymentMethod
    }
}

// MARK: - Methods for rendering a SwiftUI Preview
//
extension ShippingLabelPaymentMethodsViewModel {

    static func sampleAccountSettings() -> ShippingLabelAccountSettings {
        return ShippingLabelAccountSettings(siteID: 1234,
                                            canManagePayments: true,
                                            canEditSettings: true,
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
