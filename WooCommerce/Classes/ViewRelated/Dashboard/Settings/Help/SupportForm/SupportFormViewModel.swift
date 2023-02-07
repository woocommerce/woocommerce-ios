import Foundation

/// Data Source for the Support Request
///
public protocol SupportFormMetaDataSource {
    /// Zendesk Form ID.
    ///
    var formID: Int64 { get }

    /// Zendesk tags
    ///
    var tags: [String] { get }

    /// Zendesk Custom Fields
    ///
    var customFields: [Int64: String] { get }
}


/// View Model for the support form.
///
public final class SupportFormViewModel {

    /// Zendesk metadata provider.
    ///
    private let dataSource: SupportFormMetaDataSource

    init(dataSource: SupportFormMetaDataSource) {
        self.dataSource = dataSource
    }

    /// Submits the support request using the Zendesk Provider.
    ///
    func submitSupportRequest(onCompletion: @escaping (Result<Void, Error>) -> Void) {
        ZendeskProvider.shared.createSupportRequest(formID: dataSource.formID,
                                                    customFields: dataSource.customFields,
                                                    tags: dataSource.tags,
                                                    subject: "Temporary Subject",
                                                    description: "Temporary Description",
                                                    onCompletion: onCompletion)
    }
}
