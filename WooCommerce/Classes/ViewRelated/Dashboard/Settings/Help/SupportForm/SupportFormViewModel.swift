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
public final class SupportFormViewModel: ObservableObject {

    /// Variable that holds the area of support for better routing.
    ///
    @Published var area: Area

    /// Variable that holds the subject of the ticket.
    ///
    @Published var subject = ""

    /// Variable that holds the description of the ticket.
    ///
    @Published var description = ""

    /// Supported support areas.
    ///
    let areas: [Area] = [
        .init(title: Localization.mobileApp),
        .init(title: Localization.ipp),
        .init(title: Localization.wcPayments),
        .init(title: Localization.wcPlugin),
        .init(title: Localization.otherPlugin),
    ]

    /// Zendesk metadata provider.
    ///
    private let dataSource: SupportFormMetaDataSource

    init(dataSource: SupportFormMetaDataSource) {
        self.dataSource = dataSource
        self.area = areas[0] // Preselect the first area.
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

// MARK: Definitions
extension SupportFormViewModel {
    struct Area: Hashable {
        /// Area title.
        ///
        let title: String

        /// Area tags. To be filled later.
        ///
        let tags: [String] = []

        /// Area form id. To be filled later.
        ///
        let formID: Int64 = 0
    }
}

// MARK: Constants
private extension SupportFormViewModel {
    enum Localization {
        static let mobileApp = NSLocalizedString("Mobile App", comment: "Title of the mobile app support area option")
        static let ipp = NSLocalizedString("Card Reader / In-Person Payments", comment: "Title of the card reader support area option")
        static let wcPayments = NSLocalizedString("WooCommerce Payments", comment: "Title of the WooCommerce Payments support area option")
        static let wcPlugin = NSLocalizedString("WooCommerce Plugin", comment: "Title of the WooCommerce Plugin support area option")
        static let otherPlugin = NSLocalizedString("Other Extension / Plugin", comment: "Title of the Other Plugin support area option")
    }
}
