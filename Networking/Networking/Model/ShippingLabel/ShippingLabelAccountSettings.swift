import Foundation

/// Represents Account Settings for Shipping Labels.
///
public struct ShippingLabelAccountSettings: Equatable, GeneratedFakeable {
    /// Remote Site ID.
    public let siteID: Int64

    /// Whether the current user can make changes to the payments section.
    public let canManagePayments: Bool

    /// Whether the current user can edit non-payment settings.
    public let canEditSettings: Bool

    /// Store owner's display name.
    public let storeOwnerDisplayName: String

    /// Store owner's username.
    public let storeOwnerUsername: String

    /// Store owner's WordPress.com username.
    public let storeOwnerWpcomUsername: String

    /// Store owner's WordPress.com email.
    public let storeOwnerWpcomEmail: String

    /// Available payment methods for the store.
    /// This is an empty array if there are no payment methods available.
    public let paymentMethods: [ShippingLabelPaymentMethod]

    /// Selected payment method.
    /// This is `0` if no payment method is available.
    public let selectedPaymentMethodID: Int64

    /// Whether receipts for shipping label purchases should be emailed to the store owner.
    public let isEmailReceiptsEnabled: Bool

    /// Default paper size for shipping labels.
    public let paperSize: ShippingLabelPaperSize

    /// The last selected package for shipping labels.
    /// Uses the `id` for predefined packages or `name` for custom packages.
    public let lastSelectedPackageID: String

    public init(siteID: Int64,
                canManagePayments: Bool,
                canEditSettings: Bool,
                storeOwnerDisplayName: String,
                storeOwnerUsername: String,
                storeOwnerWpcomUsername: String,
                storeOwnerWpcomEmail: String,
                paymentMethods: [ShippingLabelPaymentMethod],
                selectedPaymentMethodID: Int64,
                isEmailReceiptsEnabled: Bool,
                paperSize: ShippingLabelPaperSize,
                lastSelectedPackageID: String) {
        self.siteID = siteID
        self.canManagePayments = canManagePayments
        self.canEditSettings = canEditSettings
        self.storeOwnerDisplayName = storeOwnerDisplayName
        self.storeOwnerUsername = storeOwnerUsername
        self.storeOwnerWpcomUsername = storeOwnerWpcomUsername
        self.storeOwnerWpcomEmail = storeOwnerWpcomEmail
        self.paymentMethods = paymentMethods
        self.selectedPaymentMethodID = selectedPaymentMethodID
        self.isEmailReceiptsEnabled = isEmailReceiptsEnabled
        self.paperSize = paperSize
        self.lastSelectedPackageID = lastSelectedPackageID
    }
}

extension ShippingLabelAccountSettings: Decodable {
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw ShippingLabelAccountSettingsDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let formMetaContainer = try container.nestedContainer(keyedBy: FormMetaKeys.self, forKey: .formMeta)
        let canManagePayments = try formMetaContainer.decode(Bool.self, forKey: .canManagePayments)
        let canEditSettings = try formMetaContainer.decode(Bool.self, forKey: .canEditSettings)
        let storeOwnerDisplayName = try formMetaContainer.decode(String.self, forKey: .storeOwnerDisplayName)
        let storeOwnerUsername = try formMetaContainer.decode(String.self, forKey: .storeOwnerUsername)
        let storeOwnerWpcomUsername = try formMetaContainer.decode(String.self, forKey: .storeOwnerWpcomUsername)
        let storeOwnerWpcomEmail = try formMetaContainer.decode(String.self, forKey: .storeOwnerWpcomEmail)
        let paymentMethods = try formMetaContainer.decodeIfPresent([ShippingLabelPaymentMethod].self, forKey: .paymentMethods) ?? []

        let formDataContainer = try container.nestedContainer(keyedBy: FormDataKeys.self, forKey: .formData)
        let selectedPaymentMethodID = try formDataContainer.decode(Int64.self, forKey: .selectedPaymentMethodID)
        let isEmailReceiptsEnabled = try formDataContainer.decode(Bool.self, forKey: .isEmailReceiptsEnabled)
        let paperSizeRawValue = try formDataContainer.decode(String.self, forKey: .paperSize)
        let paperSize = ShippingLabelPaperSize(rawValue: paperSizeRawValue)

        let userMetaContainer = try container.nestedContainer(keyedBy: UserMetaKeys.self, forKey: .userMeta)
        let lastSelectedPackageID = try userMetaContainer.decode(String.self, forKey: .lastSelectedPackageID)

        self.init(siteID: siteID,
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

/// Defines all of the ShippingLabelAccountSettings CodingKeys
///
private extension ShippingLabelAccountSettings {
    private enum CodingKeys: String, CodingKey {
        case formData
        case formMeta
        case userMeta
    }

    private enum FormDataKeys: String, CodingKey {
        case selectedPaymentMethodID = "selected_payment_method_id"
        case isEmailReceiptsEnabled = "email_receipts"
        case paperSize = "paper_size"
    }

    private enum FormMetaKeys: String, CodingKey {
        case canManagePayments = "can_manage_payments"
        case canEditSettings = "can_edit_settings"
        case storeOwnerDisplayName = "master_user_name"
        case storeOwnerUsername = "master_user_login"
        case storeOwnerWpcomUsername = "master_user_wpcom_login"
        case storeOwnerWpcomEmail = "master_user_email"
        case paymentMethods = "payment_methods"
    }

    private enum UserMetaKeys: String, CodingKey {
        case lastSelectedPackageID = "last_box_id"
    }
}

// MARK: - Decoding Errors
//
enum ShippingLabelAccountSettingsDecodingError: Error {
    case missingSiteID
}
