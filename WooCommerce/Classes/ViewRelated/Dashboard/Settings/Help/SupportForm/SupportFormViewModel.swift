import Foundation
import class WordPressShared.EmailFormatValidator
import protocol WooFoundation.Analytics
import struct Yosemite.Site

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

    /// Variable that holds the siteAddress of the ticket.
    ///
    @Published var siteAddress = ""

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

    /// To fetch the default site URL if possible.
    ///
    private let defaultSite: Site?

    /// Defines when the submit button should be enabled or not.
    ///
    var submitButtonDisabled: Bool {
        area == nil || subject.isEmpty || siteAddress.isEmpty || description.isEmpty
    }

    var identitySubmitButtonDisabled: Bool {
        !EmailFormatValidator.validate(string: contactEmailAddress)
    }

    @Published var contactName: String = ""
    @Published var contactEmailAddress: String = ""
    @Published var shouldShowIdentityInput = false
    @Published var shouldShowErrorAlert = false
    @Published var shouldShowSuccessAlert = false

    private var error: Error?

    var errorMessage: String {
        switch error {
        case .some(ZendeskError.failedToCreateIdentity):
            return Localization.badIdentityError
        default:
            return Localization.supportRequestFailed
        }
    }

    init(areas: [Area] = wooSupportAreas(),
         sourceTag: String? = nil,
         zendeskProvider: ZendeskManagerProtocol = ZendeskProvider.shared,
         analyticsProvider: Analytics = ServiceLocator.analytics,
         defaultSite: Site? = nil) {
        self.areas = areas
        self.sourceTag = sourceTag
        self.zendeskProvider = zendeskProvider
        self.analyticsProvider = analyticsProvider
        self.defaultSite = defaultSite
    }

    /// Tracks when the support form is viewed.
    ///
    func onViewAppear() {
        analyticsProvider.track(.supportNewRequestViewed)
        requestZendeskIdentityIfNeeded()

        // Populates the site address field if there is any.
        self.siteAddress = defaultSite?.url ?? ""
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
                                             customFields: area.datasource.customFields(siteAddress: siteAddress),
                                             tags: assembleTags(),
                                             subject: subject,
                                             description: description) { [weak self] result in
            guard let self else { return }
            self.showLoadingIndicator = false

            // Analytics
            switch result {
            case .success:
                self.analyticsProvider.track(.supportNewRequestCreated)
                self.shouldShowSuccessAlert = true
            case .failure(let error):
                self.analyticsProvider.track(.supportNewRequestFailed)
                self.error = error
                self.shouldShowErrorAlert = true
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

    @MainActor
    func submitIdentityInfo() async {
        do {
            try await zendeskProvider.createIdentity(name: contactName, email: contactEmailAddress)
        } catch {
            self.error = error
            shouldShowErrorAlert = true
        }
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

// MARK: Private helpers
private extension SupportFormViewModel {
    func requestZendeskIdentityIfNeeded() {
        guard !zendeskProvider.haveUserIdentity else {
            DDLogDebug("Using existing Zendesk identity")
            return
        }

        let identity = zendeskProvider.retrieveUserInfoIfAvailable()
        contactName = identity.name ?? ""
        contactEmailAddress = identity.emailAddress ?? ""
        shouldShowIdentityInput = true
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
        static let badIdentityError = NSLocalizedString(
            "supportFormViewModel.badIdentityError",
            value: "Sorry, we cannot create support requests right now, please try again later.",
            comment: "Error message when the app can't create a zendesk identity."
        )
        static let supportRequestFailed = NSLocalizedString(
            "supportFormViewModel.supportRequestFailed",
            value: "Sorry, we cannot create support requests right now, please try again later.",
            comment: "Error message when the app can't create a support request."
        )
    }
}
