import Foundation

/// Provides Mobile App Zendesk metadata.
///
struct MobileAppSupportDataSource: SupportFormMetaDataSource {
    var formID: Int64 {
        ZendeskProvider.shared.formID()
    }

    var tags: [String] {
        ZendeskProvider.shared.generalTags() + [ZendeskForms.Tags.wcMobileApps, ZendeskForms.Tags.jetpack]
    }

    var customFields: [Int64: String] {
        var generalFields = ZendeskProvider.shared.generalCustomFields()
        generalFields[ZendeskForms.IDs.subCategory] = ZendeskForms.Fields.wooMobileApps
        return generalFields
    }
}

/// Provides IPP Zendesk metadata.
///
struct IPPSupportDataSource: SupportFormMetaDataSource {
    var formID: Int64 {
        ZendeskProvider.shared.formID()
    }

    var tags: [String] {
        ZendeskProvider.shared.generalTags() + [ZendeskForms.Tags.wcMobileApps, ZendeskForms.Tags.productAreaIPP, ZendeskForms.Tags.wcPayments]
    }

    var customFields: [Int64: String] {
        var generalFields = ZendeskProvider.shared.generalCustomFields()
        generalFields[ZendeskForms.IDs.subCategory] = ZendeskForms.Fields.wooMobileApps
        return generalFields
    }
}

/// Provides WC Plugins Zendesk metadata.
///
struct WCPluginsSupportDataSource: SupportFormMetaDataSource {
    var formID: Int64 {
        ZendeskProvider.shared.wcPayFormID()
    }

    var tags: [String] {
        ZendeskProvider.shared.generalTags() + [ZendeskForms.Tags.wcCore, ZendeskForms.Tags.appTransfer, ZendeskForms.Tags.support]
    }

    var customFields: [Int64: String] {
        var generalFields = ZendeskProvider.shared.generalCustomFields()
        generalFields[ZendeskForms.IDs.category] = ZendeskForms.Fields.support
        return generalFields
    }
}

/// Provides WC Payments Zendesk metadata.
///
struct WCPaySupportDataSource: SupportFormMetaDataSource {
    var formID: Int64 {
        ZendeskProvider.shared.wcPayFormID()
    }

    var tags: [String] {
        ZendeskProvider.shared.wcPayTags() + [ZendeskForms.Tags.appTransfer]
    }

    var customFields: [Int64: String] {
        ZendeskProvider.shared.wcPayCustomFields()
    }
}

/// Provides Other Plugins Zendesk metadata.
///
struct OtherPluginsSupportDataSource: SupportFormMetaDataSource {
    var formID: Int64 {
        ZendeskProvider.shared.wcPayFormID()
    }

    var tags: [String] {
        ZendeskProvider.shared.generalTags() + [ZendeskForms.Tags.productAreaWooExtensions,
                                                ZendeskForms.Tags.appTransfer,
                                                ZendeskForms.Tags.support,
                                                ZendeskForms.Tags.store]
    }

    var customFields: [Int64: String] {
        var generalFields = ZendeskProvider.shared.generalCustomFields()
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
        static let category: Int64 = 25176003
        static let subCategory: Int64 = 25176023
    }

    /// Custom Field Values
    ///
    enum Fields {
        static let wooMobileApps = "WooCommerce Mobile Apps"
        static let support = "support"
        static let store = "store"
    }

    /// Common Tags
    ///
    enum Tags {
        static let support = Fields.support
        static let store = Fields.store
        static let jetpack = "jetpack"
        static let wcCore = "woocommerce_core"
        static let wcPayments = "woocommerce_payments"
        static let appTransfer = "mobile_app_woo_transfer"
        static let wcMobileApps = "woocommerce_mobile_apps"
        static let productAreaIPP = "product_area_apps_in_person_payments"
        static let productAreaWooExtensions = "product_area_woo_extensions"
    }
}
