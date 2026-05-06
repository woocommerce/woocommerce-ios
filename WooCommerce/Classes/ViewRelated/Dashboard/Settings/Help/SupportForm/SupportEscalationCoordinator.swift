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
    init(navigationController: UINavigationController?,
         additionalAttachmentsProvider: @escaping () -> [ZendeskAttachment] = { [] },
         zendeskProvider: ZendeskManagerProtocol = ZendeskProvider.shared,
         analytics: Analytics = ServiceLocator.analytics,
         stores: StoresManager = ServiceLocator.stores) {
        self.navigationController = navigationController
        self.additionalAttachmentsProvider = additionalAttachmentsProvider
        self.zendeskProvider = zendeskProvider
        self.analytics = analytics
        self.stores = stores
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
    func handleEscalation(chatID: Int64?, transcript: String, supportAreaInfo: SupportAreaInfo?) {
        self.chatID = chatID

        guard let supportAreaInfo else {
            showSupportForm(transcript: transcript, preselectedArea: nil)
            return
        }

        // Only create ticket directly if high confidence AND user identity exists.
        // Without identity, Zendesk can't send email responses to the user.
        if supportAreaInfo.isHighConfidence && zendeskProvider.haveUserIdentity {
            createTicketDirectly(with: supportAreaInfo)
        } else {
            showSupportForm(transcript: transcript, preselectedArea: supportAreaInfo.area)
        }
    }

    // MARK: - Private Methods

    private func showSupportForm(transcript: String, preselectedArea: SupportFormViewModel.Area?) {
        var attachments = buildTranscriptAttachment(transcript: transcript)
        attachments.append(contentsOf: additionalAttachmentsProvider())

        let viewModel = SupportFormViewModel(
            sourceTag: Tags.sourceTag,
            additionalTags: Tags.additionalTags,
            attachments: attachments,
            preselectedArea: preselectedArea,
            onTicketCreated: { [weak self] in
                self?.persistTicketCreated()
            }
        )
        let viewController = SupportFormHostingController(viewModel: viewModel)

        if let navigationController {
            viewController.show(from: navigationController)
        }
    }

    private func createTicketDirectly(with areaInfo: SupportAreaInfo) {
        guard let presentingVC = navigationController?.topViewController else { return }

        let loadingViewController = InProgressViewController(
            viewProperties: .init(title: Localization.creatingTicket, message: "")
        )
        presentingVC.present(loadingViewController, animated: true)

        var attachments = buildTranscriptAttachment(transcript: areaInfo.transcript)
        attachments.append(contentsOf: additionalAttachmentsProvider())

        let siteAddress = stores.sessionManager.defaultSite?.url ?? ""
        let tags = areaInfo.area.datasource.tags + Tags.additionalTags + [Tags.sourceTag]
        let request = ZendeskSupportRequest(
            formID: areaInfo.area.datasource.formID,
            customFields: areaInfo.area.datasource.customFields(siteAddress: siteAddress),
            tags: tags,
            subject: SupportFormViewModel.subject(for: areaInfo.areaType),
            description: areaInfo.firstUserMessage,
            attachments: attachments
        )

        zendeskProvider.createSupportRequest(request) { [weak self] result in
            loadingViewController.dismiss(animated: true) {
                switch result {
                case .success:
                    self?.analytics.track(.supportNewRequestCreated)
                    self?.persistTicketCreated()
                    self?.showSuccessAndPop()
                case .failure:
                    self?.analytics.track(.supportNewRequestFailed)
                    self?.showSupportForm(transcript: areaInfo.transcript, preselectedArea: areaInfo.area)
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
        alert.addAction(UIAlertAction(title: Localization.ok, style: .default) { [weak self] _ in
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

    private func buildTranscriptAttachment(transcript: String) -> [ZendeskAttachment] {
        guard !transcript.isEmpty, let data = transcript.data(using: .utf8) else {
            return []
        }
        return [ZendeskAttachment(
            data: data,
            filename: "support_chat_transcript.txt",
            contentType: "text/plain"
        )]
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
            value: "Support Request Created",
            comment: "Alert title shown after support ticket is created successfully"
        )
        static let ticketCreatedMessage = NSLocalizedString(
            "supportEscalationCoordinator.ticketCreatedMessage",
            value: "Your support request has been submitted. We'll respond via email.",
            comment: "Alert message shown after support ticket is created successfully"
        )
        static let ok = NSLocalizedString(
            "supportEscalationCoordinator.ok",
            value: "OK",
            comment: "OK button on the ticket created alert"
        )
    }
}
