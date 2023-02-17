import Foundation

/// Provides Mobile App Zendesk metadata.
///
struct MobileAppSupportDataSource: SupportFormMetaDataSource {
    var formID: Int64 {
        ZendeskProvider.shared.formID()
    }

    var tags: [String] {
        ZendeskProvider.shared.generalTags() + ["mobile_app"]
    }

    var customFields: [Int64: String] {
        ZendeskProvider.shared.generalCustomFields()
    }
}

/// Provides IPP Zendesk metadata.
///
struct IPPSupportDataSource: SupportFormMetaDataSource {
    var formID: Int64 {
        ZendeskProvider.shared.formID()
    }

    var tags: [String] {
        ZendeskProvider.shared.generalTags() + ["woocommerce_mobile_apps", "product_area_apps_in_person_payments"]
    }

    var customFields: [Int64: String] {
        ZendeskProvider.shared.generalCustomFields()
    }
}

/// Provides WC Plugins Zendesk metadata.
///
struct WCPluginsSupportDataSource: SupportFormMetaDataSource {
    var formID: Int64 {
        ZendeskProvider.shared.wcPayFormID()
    }

    var tags: [String] {
        ZendeskProvider.shared.generalTags() + ["woocommerce_core"]
    }

    var customFields: [Int64: String] {
        ZendeskProvider.shared.generalCustomFields()
    }
}

/// Provides WC Payments Zendesk metadata.
///
struct WCPaySupportDataSource: SupportFormMetaDataSource {
    var formID: Int64 {
        ZendeskProvider.shared.wcPayFormID()
    }

    var tags: [String] {
        ZendeskProvider.shared.wcPayTags()
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
        ZendeskProvider.shared.generalTags() + ["product_area_woo_extensions"]
    }

    var customFields: [Int64: String] {
        ZendeskProvider.shared.generalCustomFields()
    }
}
