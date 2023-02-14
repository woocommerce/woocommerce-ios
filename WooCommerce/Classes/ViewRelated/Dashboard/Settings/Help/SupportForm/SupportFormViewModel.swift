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
    let areas: [Area]

    init(areas: [Area] = wooSupportAreas()) {
        self.areas = areas
        self.area = areas[0] // Preselect the first area.
    }

    /// Submits the support request using the Zendesk Provider.
    ///
    func submitSupportRequest(onCompletion: @escaping (Result<Void, Error>) -> Void) {
        ZendeskProvider.shared.createSupportRequest(formID: area.datasource.formID,
                                                    customFields: area.datasource.customFields,
                                                    tags: area.datasource.tags,
                                                    subject: subject,
                                                    description: description,
                                                    onCompletion: onCompletion)
    }
}

// MARK: Definitions
extension SupportFormViewModel {
    struct Area: Hashable {
        /// Area title.
        ///
        let title: String

        /// Area data source.
        ///
        let datasource: SupportFormMetaDataSource

        /// Light implementation. This is just for UI purposes and needed due to the usage of `SupportFormMetaDataSource` as a constraint.
        ///
        public func hash(into hasher: inout Hasher) {
            hasher.combine(title)
            hasher.combine(datasource.formID)
        }

        /// implementation. This is just for UI purposes and needed due to the usage of `SupportFormMetaDataSource` as a constraint.
        ///
        static func == (lhs: SupportFormViewModel.Area, rhs: SupportFormViewModel.Area) -> Bool {
            lhs.title == rhs.title &&
            lhs.datasource.formID == rhs.datasource.formID
        }
    }
}

// MARK: Constants
private extension SupportFormViewModel {

    /// Default Woo Support Areas
    ///
    static func wooSupportAreas() -> [Area] {
        [
            .init(title: Localization.mobileApp, datasource: MobileAppSupportDataSource()),
            .init(title: Localization.ipp, datasource: IPPSupportDataSource()),
            .init(title: Localization.wcPayments, datasource: WCPaySupportDataSource()),
            .init(title: Localization.wcPlugin, datasource: WCPluginsSupportDataSource()),
            .init(title: Localization.otherPlugin, datasource: OtherPluginsSupportDataSource())
        ]
    }

    enum Localization {
        static let mobileApp = NSLocalizedString("Mobile App", comment: "Title of the mobile app support area option")
        static let ipp = NSLocalizedString("Card Reader / In-Person Payments", comment: "Title of the card reader support area option")
        static let wcPayments = NSLocalizedString("WooCommerce Payments", comment: "Title of the WooCommerce Payments support area option")
        static let wcPlugin = NSLocalizedString("WooCommerce Plugin", comment: "Title of the WooCommerce Plugin support area option")
        static let otherPlugin = NSLocalizedString("Other Extension / Plugin", comment: "Title of the Other Plugin support area option")
    }
}
