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
    @Published var area: Area?

    /// Variable that holds the subject of the ticket.
    ///
    @Published var subject = ""

    /// Variable that holds the description of the ticket.
    ///
    @Published var description = ""

    /// Determines if the loading indicator should be visible or not.
    ///
    @Published var showLoadingIndicator = false

    /// Supported support areas.
    ///
    let areas: [Area]

    /// Custom tag to identify where in the app the request is coming from.
    ///
    private let sourceTag: String?

    /// Handles the communication with Zendesk.
    ///
    private let zendeskProvider: ZendeskManagerProtocol

    /// Handles the communication with Tracks..
    ///
    private let analyticsProvider: Analytics

    /// Assign this closure to get notified when a support request creation finishes.
    ///
    var onCompletion: ((Result<Void, Error>) -> Void)?

    /// Defines when the submit button should be enabled or not.
    ///
    var submitButtonDisabled: Bool {
        area == nil || subject.isEmpty || description.isEmpty
    }

    init(areas: [Area] = wooSupportAreas(),
         sourceTag: String? = nil,
         zendeskProvider: ZendeskManagerProtocol = ZendeskProvider.shared,
         analyticsProvider: Analytics = ServiceLocator.analytics) {
        self.areas = areas
        self.sourceTag = sourceTag
        self.zendeskProvider = zendeskProvider
        self.analyticsProvider = analyticsProvider
    }

    /// Tracks when the support form is viewed.
    ///
    func trackSupportFormViewed() {
        analyticsProvider.track(.supportNewRequestViewed)
    }

    /// Selects an area.
    ///
    func selectArea(_ area: Area) {
        self.area = area
    }

    /// Determines if the given area is selected.
    ///
    func isAreaSelected(_ area: Area) -> Bool {
        self.area == area
    }

    /// Submits the support request using the Zendesk Provider.
    ///
    func submitSupportRequest() {
        guard let area else { return }

        showLoadingIndicator = true
        zendeskProvider.createSupportRequest(formID: area.datasource.formID,
                                             customFields: area.datasource.customFields,
                                             tags: assembleTags(),
                                             subject: subject,
                                             description: description) { [weak self] result in
            guard let self else { return }
            self.showLoadingIndicator = false
            self.onCompletion?(result)

            // Analytics
            switch result {
            case .success:
                self.analyticsProvider.track(.supportNewRequestCreated)
            case .failure:
                self.analyticsProvider.track(.supportNewRequestFailed)
            }
        }
    }

    /// Joins the selected area tags with the source tag(if available).
    ///
    func assembleTags() -> [String] {
        guard let area else { return [] }
        guard let sourceTag, sourceTag.isNotEmpty else {
            return area.datasource.tags
        }
        return area.datasource.tags + [sourceTag]
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
        let metadataProvider = SupportFormMetadataProvider()
        return [
            .init(title: Localization.mobileApp, datasource: MobileAppSupportDataSource(metadataProvider: metadataProvider)),
            .init(title: Localization.ipp, datasource: IPPSupportDataSource(metadataProvider: metadataProvider)),
            .init(title: Localization.wcPayments, datasource: WCPaySupportDataSource(metadataProvider: metadataProvider)),
            .init(title: Localization.wcPlugin, datasource: WCPluginsSupportDataSource(metadataProvider: metadataProvider)),
            .init(title: Localization.otherPlugin, datasource: OtherPluginsSupportDataSource(metadataProvider: metadataProvider))
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
