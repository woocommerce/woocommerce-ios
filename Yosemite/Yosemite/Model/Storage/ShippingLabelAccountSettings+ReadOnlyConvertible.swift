import Foundation
import Storage

// Storage.ShippingLabelAccountSettings: ReadOnlyConvertible Conformance.
//
extension Storage.ShippingLabelAccountSettings: ReadOnlyConvertible {
    /// Updates the Storage.ShippingLabelAccountSettings with the a ReadOnly ShippingLabelAccountSettings.
    ///
    public func update(with settings: Yosemite.ShippingLabelAccountSettings) {
        siteID = settings.siteID
        canManagePayments = settings.canManagePayments
        canEditSettings = settings.canEditSettings
        storeOwnerDisplayName = settings.storeOwnerDisplayName
        storeOwnerUsername = settings.storeOwnerUsername
        storeOwnerWpcomUsername = settings.storeOwnerWpcomUsername
        storeOwnerWpcomEmail = settings.storeOwnerWpcomEmail
        selectedPaymentMethodID = settings.selectedPaymentMethodID
        isEmailReceiptsEnabled = settings.isEmailReceiptsEnabled
        paperSize = settings.paperSize.rawValue
        lastSelectedPackageID = settings.lastSelectedPackageID
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ShippingLabelAccountSettings {
        let paymentMethodItems = paymentMethods?.map { $0.toReadOnly() } ?? []

        return ShippingLabelAccountSettings(siteID: siteID,
                                            canManagePayments: canManagePayments,
                                            canEditSettings: canEditSettings,
                                            storeOwnerDisplayName: storeOwnerDisplayName ?? "",
                                            storeOwnerUsername: storeOwnerUsername ?? "",
                                            storeOwnerWpcomUsername: storeOwnerWpcomUsername ?? "",
                                            storeOwnerWpcomEmail: storeOwnerWpcomEmail ?? "",
                                            paymentMethods: paymentMethodItems,
                                            selectedPaymentMethodID: selectedPaymentMethodID,
                                            isEmailReceiptsEnabled: isEmailReceiptsEnabled,
                                            paperSize: .init(rawValue: paperSize ?? ""),
                                            lastSelectedPackageID: lastSelectedPackageID ?? "")
    }
}
