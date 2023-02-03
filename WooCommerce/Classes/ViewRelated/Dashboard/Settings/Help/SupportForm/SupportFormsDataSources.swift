import Foundation

/// Provides general Zendesk metadata.
///
struct GeneralSupportDataSource: SupportFormMetaDataSource {
    var formID: Int64 {
        ZendeskProvider.shared.formID()
    }

    var tags: [String] {
        ZendeskProvider.shared.generalTags()
    }

    var customFields: [[Int64: String]] {
        ZendeskProvider.shared.generalCustomFields()
    }
}

/// Provides WCPay Zendesk metadata.
///
struct WCPaySupportDataSource: SupportFormMetaDataSource {
    var formID: Int64 {
        ZendeskProvider.shared.wcPayFormID()
    }

    var tags: [String] {
        ZendeskProvider.shared.wcPayTags()
    }

    var customFields: [[Int64: String]] {
        ZendeskProvider.shared.wcPayCustomFields()
    }
}
