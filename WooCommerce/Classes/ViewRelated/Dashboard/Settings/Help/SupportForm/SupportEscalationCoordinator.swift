import UIKit
import Yosemite
import protocol WooFoundation.Analytics

/// Coordinates the support escalation flow from AI chat to Zendesk ticket creation.
///
/// Handles routing based on confidence level, navigation to support form,
/// direct ticket creation, and success/failure UI feedback.
///
final class SupportEscalationCoordinator {
    typealias TranscriptConsentPresenter = (_ presentingViewController: UIViewController,
                                             _ onSendTicket: @escaping () -> Void,
                                             _ onShowContactForm: @escaping () -> Void) -> Void

    /// Tags used for AI chat escalation tickets.
    ///
    private enum Tags {
        static let sourceTag = "in_app_support_escalate"
        static let additionalTags = ["ai_skip"]
    }

    private weak var navigationController: UINavigationController?
    private let additionalAttachmentsProvider: () -> [ZendeskAttachment]
    private let attachmentProvider: SupportRequestAttachmentProviding
    private let zendeskProvider: ZendeskManagerProtocol
    private let analytics: Analytics
    private let stores: StoresManager
    private let onTicketCreated: (() -> Void)?
    private let transcriptConsentPresenter: TranscriptConsentPresenter

    /// The chat ID to update when a ticket is created. Set via `handleEscalation`.
    private var chatID: Int64?
    private var escalationSiteAddress: String?
    private var hasReceivedBotResponse = true

    /// Creates a new coordinator.
    ///
    /// - Parameters:
    ///   - navigationController: The navigation controller to present from.
    ///   - additionalAttachmentsProvider: Closure that returns extra attachments (e.g., troubleshooting logs).
    ///   - attachmentProvider: Composes diagnostics with the application log for each request.
    ///   - zendeskProvider: Zendesk service provider.
    ///   - analytics: Analytics tracker.
    ///   - stores: Stores manager for site info.
    ///   - onTicketCreated: Optional callback invoked after a Zendesk ticket is successfully created
    ///     (either via the form path or the high-confidence direct path), so the chat surface can
    ///     update its in-session state.
    init(navigationController: UINavigationController?,
         additionalAttachmentsProvider: @escaping () -> [ZendeskAttachment] = { [] },
         attachmentProvider: SupportRequestAttachmentProviding = DefaultSupportRequestAttachmentProvider(),
         zendeskProvider: ZendeskManagerProtocol = ZendeskProvider.shared,
         analytics: Analytics = ServiceLocator.analytics,
         stores: StoresManager = ServiceLocator.stores,
         onTicketCreated: (() -> Void)? = nil,
         transcriptConsentPresenter: TranscriptConsentPresenter? = nil) {
        self.navigationController = navigationController
        self.additionalAttachmentsProvider = additionalAttachmentsProvider
        self.attachmentProvider = attachmentProvider
        self.zendeskProvider = zendeskProvider
        self.analytics = analytics
        self.stores = stores
        self.onTicketCreated = onTicketCreated
        self.transcriptConsentPresenter = transcriptConsentPresenter ?? Self.presentTranscriptConsentAlert
    }

    /// Handles the escalation from AI chat to human support.
    ///
    /// Routes based on confidence level:
    /// - High confidence: Creates ticket directly
    /// - Otherwise: Shows support form with optional pre-selection
    ///
    /// - Parameters:
    ///   - chatID: The chat ID to associate with the created ticket (nil if chat not yet persisted).
    ///   - transcript: The chat transcript.
    ///   - supportAreaInfo: Optional support area information from AI chat.
    ///   - entryPoint: The chat entry point for analytics tracking.
    ///   - siteAddress: Optional site address to prefill the form or attach to a direct ticket.
    func handleEscalation(chatID: Int64?,
                          transcript: String,
                          supportAreaInfo: SupportAreaInfo?,
                          entryPoint: SupportChatViewModel.EntryPoint,
                          siteAddress: String? = nil,
                          hasReceivedBotResponse: Bool = true) {
        self.chatID = chatID
        self.escalationSiteAddress = siteAddress
        self.hasReceivedBotResponse = hasReceivedBotResponse
        let transcript = formattedTranscript(transcript)

        guard let supportAreaInfo else {
            showSupportForm(transcript: transcript, supportAreaInfo: nil, entryPoint: entryPoint)
            return
        }

        // Only offer direct ticket creation if high confidence, a nonempty transcript and user identity exist,
        // and a site URL is available. Otherwise the form lets users provide missing details.
        if supportAreaInfo.isHighConfidence && zendeskProvider.haveUserIdentity && hasSiteAddress && transcript != nil {
            confirmTranscriptConsent(for: supportAreaInfo, transcript: transcript, entryPoint: entryPoint)
        } else {
            showSupportForm(transcript: transcript, supportAreaInfo: supportAreaInfo, entryPoint: entryPoint)
        }
    }

    // MARK: - Private Methods

    private func showSupportForm(transcript: String?, supportAreaInfo: SupportAreaInfo?, entryPoint: SupportChatViewModel.EntryPoint) {
        let attachments = additionalAttachmentsProvider()

        let prefilledSubject: String?
        let prefilledDescription: String?

        if let supportAreaInfo {
            prefilledSubject = SupportFormViewModel.subject(for: supportAreaInfo.areaType)
            prefilledDescription = nil
        } else {
            prefilledSubject = nil
            prefilledDescription = nil
        }

        let viewModel = SupportFormViewModel(
            sourceTag: Tags.sourceTag,
            additionalTags: additionalTags(for: supportAreaInfo),
            zendeskProvider: zendeskProvider,
            attachmentProvider: attachmentProvider,
            attachments: attachments,
            transcript: transcript,
            preselectedArea: supportAreaInfo?.area,
            prefilledSubject: prefilledSubject,
            prefilledSiteAddress: siteAddress,
            prefilledDescription: prefilledDescription,
            onTicketCreated: { [weak self] in
                self?.analytics.track(event: WooAnalyticsEvent.SupportChat.ticketCreated(
                    route: .supportForm,
                    supportAreaInfo: supportAreaInfo,
                    entryPoint: entryPoint
                ))
                self?.persistTicketCreated()
                self?.onTicketCreated?()
            },
            onTicketCreationFailed: { [weak self] error in
                DDLogError("⛔️ Support chat ticket creation failed via support form: \(error)")
                self?.analytics.track(event: WooAnalyticsEvent.SupportChat.ticketCreationFailed(
                    route: .supportForm,
                    supportAreaInfo: supportAreaInfo,
                    entryPoint: entryPoint,
                    errorType: Self.errorType(for: error)
                ))
            }
        )
        let viewController = SupportFormHostingController(viewModel: viewModel)

        if let navigationController {
            viewController.show(from: navigationController)
        }
    }

    private func confirmTranscriptConsent(for areaInfo: SupportAreaInfo,
                                          transcript: String?,
                                          entryPoint: SupportChatViewModel.EntryPoint) {
        guard let presentingVC = navigationController?.topViewController else { return }

        transcriptConsentPresenter(
            presentingVC,
            { [weak self] in
                self?.createTicketDirectly(with: areaInfo, transcript: transcript, entryPoint: entryPoint)
            },
            { [weak self] in
                self?.showSupportForm(transcript: transcript, supportAreaInfo: areaInfo, entryPoint: entryPoint)
            }
        )
    }

    private func createTicketDirectly(with areaInfo: SupportAreaInfo,
                                      transcript: String?,
                                      entryPoint: SupportChatViewModel.EntryPoint) {
        guard let presentingVC = navigationController?.topViewController else { return }

        let loadingViewController = InProgressViewController(
            viewProperties: .init(title: Localization.creatingTicket, message: "")
        )
        presentingVC.present(loadingViewController, animated: true)

        let attachments = attachmentProvider.attachments(including: additionalAttachmentsProvider())

        let siteAddress = siteAddress ?? ""
        let tags = areaInfo.area.datasource.tags + additionalTags(for: areaInfo) + [Tags.sourceTag]
        let request = ZendeskSupportRequest(
            formID: areaInfo.area.datasource.formID,
            customFields: areaInfo.area.datasource.customFields(siteAddress: siteAddress),
            tags: tags,
            subject: SupportFormViewModel.subject(for: areaInfo.areaType),
            description: transcript ?? "",
            attachments: attachments
        )

        zendeskProvider.createSupportRequest(request) { [weak self] result in
            loadingViewController.dismiss(animated: true) {
                switch result {
                case .success:
                    self?.analytics.track(event: WooAnalyticsEvent.SupportChat.ticketCreated(
                        route: .directTicketCreation,
                        supportAreaInfo: areaInfo,
                        entryPoint: entryPoint
                    ))
                    self?.persistTicketCreated()
                    self?.onTicketCreated?()
                    self?.showSuccessAndPop()
                case .failure(let error):
                    DDLogError("⛔️ Support chat ticket creation failed via direct ticket creation: \(error)")
                    self?.analytics.track(event: WooAnalyticsEvent.SupportChat.ticketCreationFailed(
                        route: .directTicketCreation,
                        supportAreaInfo: areaInfo,
                        entryPoint: entryPoint,
                        errorType: Self.errorType(for: error)
                    ))
                    self?.showSupportForm(transcript: transcript, supportAreaInfo: areaInfo, entryPoint: entryPoint)
                }
            }
        }
    }

    private func showSuccessAndPop() {
        guard let topViewController = navigationController?.topViewController else {
            return
        }

        let alert = UIAlertController(
            title: Localization.ticketCreatedTitle,
            message: Localization.ticketCreatedMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: Localization.gotIt, style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        topViewController.present(alert, animated: true)
    }

    /// Persists that a ticket was created for this chat.
    private func persistTicketCreated() {
        guard let chatID else { return }
        let action = SupportChatAction.markTicketCreated(chatID: chatID) { }
        stores.dispatch(action)
    }

    private func additionalTags(for supportAreaInfo: SupportAreaInfo?) -> [String] {
        var tags = hasReceivedBotResponse ? Tags.additionalTags : []
        if let topic = supportAreaInfo?.topic, topic.isNotEmpty {
            tags.append(topic)
        }
        return tags
    }

    private var hasSiteAddress: Bool {
        siteAddress?.isNotEmpty == true
    }

    private var siteAddress: String? {
        if let siteAddress = escalationSiteAddress, siteAddress.isNotEmpty {
            return siteAddress
        }
        if let siteAddress = stores.sessionManager.defaultSite?.url, siteAddress.isNotEmpty {
            return siteAddress
        }
        return nil
    }

    private func formattedTranscript(_ transcript: String?) -> String? {
        guard let transcript,
              transcript.trimmingCharacters(in: .whitespacesAndNewlines).isNotEmpty else {
            return nil
        }
        return [Localization.transcriptHeader, transcript].joined(separator: "\n\n")
    }

    private static func errorType(for error: Error) -> String {
        switch error {
        case ZendeskError.failedToCreateIdentity:
            return "identity_creation_failed"
        default:
            return "zendesk_request_failed"
        }
    }

    private static func presentTranscriptConsentAlert(from presentingViewController: UIViewController,
                                                      onSendTicket: @escaping () -> Void,
                                                      onShowContactForm: @escaping () -> Void) {
        let alert = UIAlertController(
            title: Localization.transcriptConsentTitle,
            message: Localization.transcriptConsentMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: Localization.sendTicket, style: .default) { _ in
            onSendTicket()
        })
        alert.addAction(UIAlertAction(title: Localization.contactForm, style: .default) { _ in
            onShowContactForm()
        })
        alert.addAction(UIAlertAction(title: Localization.cancel, style: .cancel))
        presentingViewController.present(alert, animated: true)
    }
}

// MARK: - Localization

private extension SupportEscalationCoordinator {
    enum Localization {
        static let creatingTicket = NSLocalizedString(
            "supportEscalationCoordinator.creatingTicket",
            value: "Creating support request...",
            comment: "Loading message shown while creating a support ticket"
        )
        static let ticketCreatedTitle = NSLocalizedString(
            "supportEscalationCoordinator.ticketCreatedTitle",
            value: "Request Sent!",
            comment: "Alert title shown after support ticket is created successfully"
        )
        static let ticketCreatedMessage = NSLocalizedString(
            "supportEscalationCoordinator.ticketCreatedMessage",
            value: "Your support request has landed safely in our inbox. We will reply via email as quickly as we can.",
            comment: "Alert message shown after support ticket is created successfully"
        )
        static let gotIt = NSLocalizedString(
            "supportEscalationCoordinator.gotIt",
            value: "Got it",
            comment: "Button on the ticket created alert"
        )
        static let transcriptConsentTitle = NSLocalizedString(
            "supportEscalationCoordinator.transcriptConsentTitle",
            value: "Send this chat to support?",
            comment: "Title for the alert asking consent to send an AI chat transcript to support"
        )
        static let transcriptConsentMessage = NSLocalizedString(
            "supportEscalationCoordinator.transcriptConsentMessageV2",
            value: "Both options include this chat transcript. Send the request now, or open the contact form to add more details first.",
            comment: "Message for the alert asking consent to send an AI chat transcript to support"
        )
        static let contactForm = NSLocalizedString(
            "supportEscalationCoordinator.contactForm",
            value: "Contact Form",
            comment: "Button on the transcript consent alert that opens the support contact form"
        )
        static let sendTicket = NSLocalizedString(
            "supportEscalationCoordinator.sendTicket",
            value: "Send Request",
            comment: "Button on the transcript consent alert that sends the chat transcript as a support request"
        )
        static let cancel = NSLocalizedString(
            "supportEscalationCoordinator.cancel",
            value: "Cancel",
            comment: "Button on the transcript consent alert that dismisses without taking action"
        )
        static let transcriptHeader = NSLocalizedString(
            "supportEscalationCoordinator.transcriptHeader",
            value: "Following is the transcript of an in-app AI support chat session:",
            comment: "Header text before the chat transcript in support ticket description"
        )
    }
}
