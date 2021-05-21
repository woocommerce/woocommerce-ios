import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// View model for `ShippingLabelPaymentMethods`.
///
final class ShippingLabelPaymentMethodsViewModel: ObservableObject {

    private var accountSettings: ShippingLabelAccountSettings?

    @Published var selectedPaymentMethodID: Int64
    @Published var isEmailReceiptsEnabled: Bool

    var paymentMethods: [ShippingLabelPaymentMethod] {
        accountSettings?.paymentMethods ?? []
    }

    var storeOwnerUsername: String {
        accountSettings?.storeOwnerUsername ?? ""
    }

    var storeOwnerDisplayName: String {
        accountSettings?.storeOwnerDisplayName ?? ""
    }

    var storeOwnerWPcomUsername: String {
        accountSettings?.storeOwnerWpcomUsername ?? ""
    }

    var storeOwnerWPcomEmail: String {
        accountSettings?.storeOwnerWpcomEmail ?? ""
    }

    init(accountSettings: ShippingLabelAccountSettings?,
         selectedPaymentMethodID: Int64) {
        self.accountSettings = accountSettings
        self.selectedPaymentMethodID = selectedPaymentMethodID
        self.isEmailReceiptsEnabled = accountSettings?.isEmailReceiptsEnabled ?? false
    }

    func didSelectPaymentMethod(withID paymentMethodID: Int64) {
        selectedPaymentMethodID = paymentMethodID
    }
}

// MARK: - Methods for rendering a SwiftUI Preview
//
extension ShippingLabelPaymentMethodsViewModel {

    static let samplePaymentMethodID: Int64 = 11743265

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
