import UIKit
import Yosemite
import protocol WooFoundation.Analytics

/// Coordinates the support escalation flow from AI chat to Zendesk ticket creation.
///
/// Handles routing based on confidence level, navigation to support form,
/// direct ticket creation, and success/failure UI feedback.
///
final class SupportEscalationCoordinator {

    /// Tags used for AI chat escalation tickets.
    ///
    private enum Tags {
        static let sourceTag = "in_app_support_escalate"
        static let additionalTags = ["ai_skip"]
    }

    private weak var navigationController: UINavigationController?
    private let additionalAttachmentsProvider: () -> [ZendeskAttachment]
    private let zendeskProvider: ZendeskManagerProtocol
    private let analytics: Analytics
    private let stores: StoresManager
    private let onTicketCreated: (() -> Void)?

    /// The chat ID to update when a ticket is created. Set via `handleEscalation`.
    private var chatID: Int64?

    /// Creates a new coordinator.
    ///
    /// - Parameters:
    ///   - navigationController: The navigation controller to present from.
    ///   - additionalAttachmentsProvider: Closure that returns extra attachments (e.g., troubleshooting logs).
    ///   - zendeskProvider: Zendesk service provider.
    ///   - analytics: Analytics tracker.
    ///   - stores: Stores manager for site info.
    ///   - onTicketCreated: Optional callback invoked after a Zendesk ticket is successfully created
    ///     (either via the form path or the high-confidence direct path), so the chat surface can
    ///     update its in-session state.
    init(navigationController: UINavigationController?,
         additionalAttachmentsProvider: @escaping () -> [ZendeskAttachment] = { [] },
         zendeskProvider: ZendeskManagerProtocol = ZendeskProvider.shared,
         analytics: Analytics = ServiceLocator.analytics,
         stores: StoresManager = ServiceLocator.stores,
         onTicketCreated: (() -> Void)? = nil) {
        self.navigationController = navigationController
        self.additionalAttachmentsProvider = additionalAttachmentsProvider
        self.zendeskProvider = zendeskProvider
        self.analytics = analytics
        self.stores = stores
        self.onTicketCreated = onTicketCreated
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
    func handleEscalation(chatID: Int64?, transcript: String, supportAreaInfo: SupportAreaInfo?, entryPoint: SupportChatViewModel.EntryPoint) {
        self.chatID = chatID

        guard let supportAreaInfo else {
            showSupportForm(transcript: transcript, supportAreaInfo: nil, entryPoint: entryPoint)
            return
        }

        // Only create ticket directly if high confidence AND user identity exists.
        // Without identity, Zendesk can't send email responses to the user.
        if supportAreaInfo.isHighConfidence && zendeskProvider.haveUserIdentity {
            createTicketDirectly(with: supportAreaInfo, entryPoint: entryPoint)
        } else {
            showSupportForm(transcript: transcript, supportAreaInfo: supportAreaInfo, entryPoint: entryPoint)
        }
    }

    // MARK: - Private Methods

    private func showSupportForm(transcript: String, supportAreaInfo: SupportAreaInfo?, entryPoint: SupportChatViewModel.EntryPoint) {
        let attachments = additionalAttachmentsProvider()

        let prefilledSubject: String?
        let prefilledDescription: String?

        if let supportAreaInfo {
            prefilledSubject = SupportFormViewModel.subject(for: supportAreaInfo.areaType)
            prefilledDescription = [Localization.transcriptHeader, transcript].joined(separator: "\n\n")
        } else {
            prefilledSubject = nil
            prefilledDescription = nil
        }

        let viewModel = SupportFormViewModel(
            sourceTag: Tags.sourceTag,
            additionalTags: additionalTags(for: supportAreaInfo),
            zendeskProvider: zendeskProvider,
            attachments: attachments,
            preselectedArea: supportAreaInfo?.area,
            prefilledSubject: prefilledSubject,
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

    private func createTicketDirectly(with areaInfo: SupportAreaInfo, entryPoint: SupportChatViewModel.EntryPoint) {
        guard let presentingVC = navigationController?.topViewController else { return }

        let loadingViewController = InProgressViewController(
            viewProperties: .init(title: Localization.creatingTicket, message: "")
        )
        presentingVC.present(loadingViewController, animated: true)

        let description = [Localization.transcriptHeader, areaInfo.transcript].joined(separator: "\n\n")
        let attachments = additionalAttachmentsProvider()

        let siteAddress = stores.sessionManager.defaultSite?.url ?? ""
        let tags = areaInfo.area.datasource.tags + additionalTags(for: areaInfo) + [Tags.sourceTag]
        let request = ZendeskSupportRequest(
            formID: areaInfo.area.datasource.formID,
            customFields: areaInfo.area.datasource.customFields(siteAddress: siteAddress),
            tags: tags,
            subject: SupportFormViewModel.subject(for: areaInfo.areaType),
            description: description,
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
                    self?.analytics.track(event: WooAnalyticsEvent.SupportChat.ticketCreationFailed(
                        route: .directTicketCreation,
                        supportAreaInfo: areaInfo,
                        entryPoint: entryPoint,
                        errorType: Self.errorType(for: error)
                    ))
                    self?.showSupportForm(transcript: areaInfo.transcript, supportAreaInfo: areaInfo, entryPoint: entryPoint)
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
        var tags = Tags.additionalTags
        if let topic = supportAreaInfo?.topic, topic.isNotEmpty {
            tags.append(topic)
        }
        return tags
    }

    private static func errorType(for error: Error) -> String {
        switch error {
        case ZendeskError.failedToCreateIdentity:
            return "identity_creation_failed"
        default:
            return "zendesk_request_failed"
        }
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
        static let transcriptHeader = NSLocalizedString(
            "supportEscalationCoordinator.transcriptHeader",
            value: "Following is the transcript of an in-app AI support chat session:",
            comment: "Header text before the chat transcript in support ticket description"
        )
    }
}
