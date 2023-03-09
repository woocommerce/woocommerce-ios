import Foundation

/// Provides Mobile App Zendesk metadata.
///
struct MobileAppSupportDataSource: SupportFormMetaDataSource {
    let metadataProvider: SupportFormMetadataProvider

    var formID: Int64 {
        ZendeskForms.IDs.mobileForm
    }

    var tags: [String] {
        metadataProvider.systemTags() + [ZendeskForms.Tags.wcMobileApps, ZendeskForms.Tags.jetpack]
    }

    var customFields: [Int64: String] {
        var generalFields = metadataProvider.systemFields()
        generalFields[ZendeskForms.IDs.subCategory] = ZendeskForms.Fields.wooMobileApps
        return generalFields
    }
}

/// Provides IPP Zendesk metadata.
///
struct IPPSupportDataSource: SupportFormMetaDataSource {
    let metadataProvider: SupportFormMetadataProvider

    var formID: Int64 {
        ZendeskForms.IDs.mobileForm
    }

    var tags: [String] {
        metadataProvider.systemTags() + [ZendeskForms.Tags.wcMobileApps, ZendeskForms.Tags.productAreaIPP, ZendeskForms.Tags.wcPayments]
    }

    var customFields: [Int64: String] {
        var generalFields = metadataProvider.systemFields()
        generalFields[ZendeskForms.IDs.subCategory] = ZendeskForms.Fields.wooMobileApps
        return generalFields
    }
}

/// Provides WC Plugins Zendesk metadata.
///
struct WCPluginsSupportDataSource: SupportFormMetaDataSource {
    let metadataProvider: SupportFormMetadataProvider

    var formID: Int64 {
        ZendeskForms.IDs.wooForm
    }

    var tags: [String] {
        metadataProvider.systemTags() + [ZendeskForms.Tags.wcCore, ZendeskForms.Tags.appTransfer, ZendeskForms.Tags.support]
    }

    var customFields: [Int64: String] {
        var generalFields = metadataProvider.systemFields()
        generalFields[ZendeskForms.IDs.category] = ZendeskForms.Fields.support
        return generalFields
    }
}

/// Provides WC Payments Zendesk metadata.
///
struct WCPaySupportDataSource: SupportFormMetaDataSource {
    let metadataProvider: SupportFormMetadataProvider

    var formID: Int64 {
        ZendeskForms.IDs.wooForm
    }

    var tags: [String] {
        metadataProvider.systemTags() + [ZendeskForms.Tags.appTransfer,
                                                      ZendeskForms.Tags.wcPayments,
                                                      ZendeskForms.Tags.payment,
                                                      ZendeskForms.Tags.support,
                                                      ZendeskForms.Tags.productAreaWCPayments]
    }

    var customFields: [Int64: String] {
        var generalFields = metadataProvider.systemFields()
        generalFields[ZendeskForms.IDs.category] = ZendeskForms.Fields.support
        generalFields[ZendeskForms.IDs.subCategory] = ZendeskForms.Fields.payment
        return generalFields
    }
}

/// Provides Other Plugins Zendesk metadata.
///
struct OtherPluginsSupportDataSource: SupportFormMetaDataSource {
    let metadataProvider: SupportFormMetadataProvider

    var formID: Int64 {
        ZendeskForms.IDs.wooForm
    }

    var tags: [String] {
        metadataProvider.systemTags() + [ZendeskForms.Tags.productAreaWooExtensions,
                                                      ZendeskForms.Tags.appTransfer,
                                                      ZendeskForms.Tags.support,
                                                      ZendeskForms.Tags.store]
    }

    var customFields: [Int64: String] {
        var generalFields = metadataProvider.systemFields()
        generalFields[ZendeskForms.IDs.category] = ZendeskForms.Fields.support
        generalFields[ZendeskForms.IDs.subCategory] = ZendeskForms.Fields.store
        return generalFields
    }
}

/// Zendesk Constant Values
///
private enum ZendeskForms {
    /// Custom Field IDs
    ///
    enum IDs {
        static let mobileForm: Int64 = 360000010286
        static let wooForm: Int64 = 189946
        static let category: Int64 = 25176003
        static let subCategory: Int64 = 25176023
    }

    /// Custom Field Values
    ///
    enum Fields {
        static let wooMobileApps = "WooCommerce Mobile Apps"
        static let support = "support"
        static let store = "store"
        static let payment = "payment"
    }

    /// Common Tags
    ///
    enum Tags {
        static let support = Fields.support
        static let store = Fields.store
        static let payment = Fields.payment
        static let jetpack = "jetpack"
        static let wcCore = "woocommerce_core"
        static let wcPayments = "woocommerce_payments"
        static let appTransfer = "mobile_app_woo_transfer"
        static let wcMobileApps = "woocommerce_mobile_apps"
        static let productAreaIPP = "product_area_apps_in_person_payments"
        static let productAreaWooExtensions = "product_area_woo_extensions"
        static let productAreaWCPayments = "product_area_woo_payment_gateway"
    }
}
