import Yosemite

/// Generates mock `ShippingLabelAccountSettings`
///
public struct MockShippingLabelAccountSettings {
    public static func sampleAccountSettings(siteID: Int64 = 0,
                                             canManagePayments: Bool = true,
                                             canEditSettings: Bool = true,
                                             storeOwnerDisplayName: String = "",
                                             storeOwnerUsername: String = "",
                                             storeOwnerWpcomUsername: String = "",
                                             storeOwnerWpcomEmail: String = "",
                                             paymentMethods: [ShippingLabelPaymentMethod] = [],
                                             selectedPaymentMethodID: Int64 = 0,
                                             isEmailReceiptsEnabled: Bool = true,
                                             paperSize: ShippingLabelPaperSize = .label,
                                             lastSelectedPackageID: String = "") -> ShippingLabelAccountSettings {
        .init(siteID: siteID,
              canManagePayments: canManagePayments,
              canEditSettings: canEditSettings,
              storeOwnerDisplayName: storeOwnerDisplayName,
              storeOwnerUsername: storeOwnerUsername,
              storeOwnerWpcomUsername: storeOwnerWpcomUsername,
              storeOwnerWpcomEmail: storeOwnerWpcomEmail,
              paymentMethods: paymentMethods,
              selectedPaymentMethodID: selectedPaymentMethodID,
              isEmailReceiptsEnabled: isEmailReceiptsEnabled,
              paperSize: paperSize,
              lastSelectedPackageID: lastSelectedPackageID)
    }
}
