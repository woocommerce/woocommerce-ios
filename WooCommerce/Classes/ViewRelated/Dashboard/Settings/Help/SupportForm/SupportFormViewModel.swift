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

    /// Additional tags to include in the support request.
    ///
    private let additionalTags: [String]

    /// Handles the communication with Zendesk.
    ///
    private let zendeskProvider: ZendeskManagerProtocol

    private let attachmentProvider: SupportRequestAttachmentProviding

    /// Builds the app-level status report attached to every ticket.
    ///
    private let mobileStatusReportProvider: MobileStatusReportProviding

    /// Handles the communication with Tracks..
    ///
    private let analyticsProvider: Analytics

    /// To fetch the default site URL if possible.
    ///
    private let defaultSite: Site?

    private let attachments: [ZendeskAttachment]

    /// Immutable transcript context appended to the editable message when the request is submitted.
    private let transcript: String?

    /// Whether the form should disclose that an AI chat transcript will be included.
    var shouldShowTranscriptDisclosure: Bool {
        transcript?.isNonBlank == true
    }

    /// Called when a ticket is successfully created.
    private let onTicketCreated: (() -> Void)?

    /// Called when ticket creation fails.
    private let onTicketCreationFailed: ((Error) -> Void)?

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
         additionalTags: [String] = [],
         zendeskProvider: ZendeskManagerProtocol = ZendeskProvider.shared,
         analyticsProvider: Analytics = ServiceLocator.analytics,
         attachmentProvider: SupportRequestAttachmentProviding = DefaultSupportRequestAttachmentProvider(),
         mobileStatusReportProvider: MobileStatusReportProviding = MobileStatusReportProvider(),
         defaultSite: Site? = ServiceLocator.stores.sessionManager.defaultSite,
         attachments: [ZendeskAttachment] = [],
         transcript: String? = nil,
         preselectedArea: Area? = nil,
         prefilledSubject: String? = nil,
         prefilledSiteAddress: String? = nil,
         prefilledDescription: String? = nil,
         onTicketCreated: (() -> Void)? = nil,
         onTicketCreationFailed: ((Error) -> Void)? = nil) {
        self.areas = areas
        self.sourceTag = sourceTag
        self.additionalTags = additionalTags
        self.zendeskProvider = zendeskProvider
        self.analyticsProvider = analyticsProvider
        self.attachmentProvider = attachmentProvider
        self.mobileStatusReportProvider = mobileStatusReportProvider
        self.defaultSite = defaultSite
        self.attachments = attachments
        self.transcript = transcript
        self.area = preselectedArea
        self.onTicketCreated = onTicketCreated
        self.onTicketCreationFailed = onTicketCreationFailed

        if let prefilledSubject {
            self.subject = prefilledSubject
        }
        if let prefilledSiteAddress {
            self.siteAddress = prefilledSiteAddress
        }
        if let prefilledDescription {
            self.description = prefilledDescription
        }
    }

    /// Tracks when the support form is viewed.
    ///
    func onViewAppear() {
        analyticsProvider.track(.supportNewRequestViewed)
        requestZendeskIdentityIfNeeded()

        // Populates the site address field if there is any.
        if siteAddress.isEmpty {
            self.siteAddress = defaultSite?.url ?? ""
        }
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
    /// Async because the Mobile Status Report reads notification settings and the POS catalog, neither of which
    /// can be read synchronously. It is generated here rather than prefetched so it always describes the app as
    /// it was when the ticket was filed.
    ///
    @MainActor
    func submitSupportRequest() async {
        guard let area else { return }

        showLoadingIndicator = true

        let mobileStatusReport = await mobileStatusReportProvider.generateReport(siteAddress: siteAddress)
        var customFields = area.datasource.customFields(siteAddress: siteAddress)
        customFields[MobileStatusReportZendesk.customFieldID] = mobileStatusReport

        let requestAttachments = attachmentProvider.attachments(including: attachments)
            + [MobileStatusReportZendesk.attachment(for: mobileStatusReport)].compactMap { $0 }

        let request = ZendeskSupportRequest(formID: area.datasource.formID,
                                            customFields: customFields,
                                            tags: assembleTags(),
                                            subject: subject,
                                            description: requestDescription,
                                            attachments: requestAttachments)
        zendeskProvider.createSupportRequest(request) { [weak self] result in
            guard let self else { return }
            self.showLoadingIndicator = false

            // Analytics
            switch result {
            case .success:
                self.analyticsProvider.track(.supportNewRequestCreated)
                self.onTicketCreated?()
                self.shouldShowSuccessAlert = true
            case .failure(let error):
                self.analyticsProvider.track(.supportNewRequestFailed)
                self.onTicketCreationFailed?(error)
                self.error = error
                self.shouldShowErrorAlert = true
            }
        }
    }

    /// Joins the selected area tags with the source tag and additional tags.
    ///
    func assembleTags() -> [String] {
        guard let area else { return [] }
        var tags = area.datasource.tags
        if let sourceTag, sourceTag.isNotEmpty {
            tags.append(sourceTag)
        }
        return tags + additionalTags
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

    var requestDescription: String {
        guard shouldShowTranscriptDisclosure, let transcript else {
            return description
        }
        return [description, transcript].joined(separator: "\n\n")
    }
}

// MARK: Constants
extension SupportFormViewModel {

    /// Default Woo Support Areas
    ///
    private static func wooSupportAreas() -> [Area] {
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
        static let wcPayments = NSLocalizedString(
            "supportFormViewModel.wooPayments",
            value: "WooPayments",
            comment: "Title of the WooPayments support area option"
        )
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
