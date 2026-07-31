import Testing
import UIKit
import Fakes
import Yosemite
@testable import WooCommerce

@MainActor
struct SupportEscalationCoordinatorTests {

    // MARK: - Routing Tests

    @Test func handleEscalation_when_supportAreaInfo_is_nil_then_shows_support_form() async throws {
        // Given
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController, zendesk: zendesk)

        // When
        coordinator.handleEscalation(chatID: nil, transcript: "Test transcript", supportAreaInfo: nil, entryPoint: .helpAndSupport)
        await coordinator.directTicketCreationTask?.value

        // Then
        #expect(zendesk.latestInvokedTags.isEmpty)
        #expect(navigationController.viewControllers.contains { $0 is SupportFormHostingController })
        try await assertSupportFormRetainsTranscript(navigationController, zendesk: zendesk)
    }

    @Test func supportForm_when_no_bot_response_then_excludes_aiSkip_tag() async {
        // Given
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController, zendesk: zendesk)

        coordinator.handleEscalation(chatID: nil,
                                     transcript: "Test transcript",
                                     supportAreaInfo: nil,
                                     entryPoint: .helpAndSupport,
                                     hasReceivedBotResponse: false)
        await coordinator.directTicketCreationTask?.value

        // When
        let viewModel = supportFormViewModel(from: navigationController)
        viewModel?.siteAddress = "https://example.com"
        await viewModel?.submitSupportRequest()

        // Then
        #expect(zendesk.latestInvokedTags.contains("ai_skip") == false)
    }

    @Test func handleEscalation_when_supportAreaInfo_is_nil_and_siteAddress_is_available_then_prefills_siteAddress() async {
        // Given
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController, zendesk: zendesk)

        // When
        coordinator.handleEscalation(chatID: nil,
                                     transcript: "Test transcript",
                                     supportAreaInfo: nil,
                                     entryPoint: .preLogin,
                                     siteAddress: "https://prelogin.example.com")

        // Then
        let viewModel = supportFormViewModel(from: navigationController)
        await coordinator.directTicketCreationTask?.value
        #expect(viewModel?.siteAddress == "https://prelogin.example.com")
    }

    @Test func handleEscalation_when_high_confidence_and_has_identity_then_creates_ticket_directly_after_transcript_consent() async throws {
        // Given
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))

        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController, zendesk: zendesk)
        let areaInfo = makeHighConfidenceSupportAreaInfo()

        // When
        coordinator.handleEscalation(chatID: nil, transcript: "Test transcript", supportAreaInfo: areaInfo, entryPoint: .helpAndSupport)
        await coordinator.directTicketCreationTask?.value

        // Then
        #expect(zendesk.latestInvokedTags.contains("in_app_support_escalate"))
        #expect(zendesk.latestInvokedTags.contains("ai_skip"))
        #expect(zendesk.latestInvokedTags.contains("woo_mobile_issue_orders"))
        let description = try #require(zendesk.latestSupportRequest?.description)
        #expect(description == expectedFormattedTranscript)
        #expect(description.components(separatedBy: "Test transcript").count == 2)
    }

    @Test func handleEscalation_when_high_confidence_and_has_identity_then_asks_for_transcript_consent_before_creating_ticket() async {
        // Given
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))

        var didAskForConsent = false
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(
            navigationController: navigationController,
            zendesk: zendesk,
            transcriptConsentPresenter: { _, _, _ in
                didAskForConsent = true
            }
        )

        // When
        coordinator.handleEscalation(chatID: nil,
                                     transcript: "Test transcript",
                                     supportAreaInfo: makeHighConfidenceSupportAreaInfo(),
                                     entryPoint: .helpAndSupport)
        await coordinator.directTicketCreationTask?.value

        // Then
        #expect(didAskForConsent)
        #expect(zendesk.latestInvokedTags.isEmpty)
    }

    @Test func handleEscalation_when_transcript_consent_contact_form_selected_then_shows_form_without_prefilled_transcript() async throws {
        // Given
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))

        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(
            navigationController: navigationController,
            zendesk: zendesk,
            transcriptConsentPresenter: { _, _, showContactForm in
                showContactForm()
            }
        )

        // When
        coordinator.handleEscalation(chatID: nil,
                                     transcript: "Test transcript",
                                     supportAreaInfo: makeHighConfidenceSupportAreaInfo(),
                                     entryPoint: .helpAndSupport)
        await coordinator.directTicketCreationTask?.value

        // Then
        #expect(zendesk.latestInvokedTags.isEmpty)
        let viewModel = try #require(supportFormViewModel(from: navigationController))
        #expect(viewModel.description.isEmpty)
        #expect(viewModel.shouldShowTranscriptDisclosure)
        #expect(viewModel.submitButtonDisabled)
        #expect(viewModel.subject == SupportFormViewModel.subject(for: .mobileApp))

        viewModel.description = "Additional details"
        await viewModel.submitSupportRequest()
        #expect(zendesk.latestSupportRequest?.description == "Additional details\n\n\(expectedFormattedTranscript)")
    }

    @Test func handleEscalation_when_transcript_consent_cancelled_then_takes_no_action() async {
        // Given
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))

        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(
            navigationController: navigationController,
            zendesk: zendesk,
            transcriptConsentPresenter: { _, _, _ in
                // Simulate tapping the alert's Cancel action.
            }
        )

        // When
        coordinator.handleEscalation(chatID: nil,
                                     transcript: "Test transcript",
                                     supportAreaInfo: makeHighConfidenceSupportAreaInfo(),
                                     entryPoint: .helpAndSupport)
        await coordinator.directTicketCreationTask?.value

        // Then
        #expect(zendesk.latestInvokedTags.isEmpty)
        #expect(navigationController.viewControllers.contains { $0 is SupportFormHostingController } == false)
    }

    @Test func handleEscalation_when_high_confidence_but_no_identity_then_shows_support_form() async throws {
        // Given
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: nil, email: nil, haveUserIdentity: false)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController, zendesk: zendesk)
        let areaInfo = makeHighConfidenceSupportAreaInfo()

        // When
        coordinator.handleEscalation(chatID: nil, transcript: "Test transcript", supportAreaInfo: areaInfo, entryPoint: .helpAndSupport)
        await coordinator.directTicketCreationTask?.value

        // Then
        #expect(zendesk.latestInvokedTags.isEmpty)
        #expect(navigationController.viewControllers.contains { $0 is SupportFormHostingController })
        try await assertSupportFormRetainsTranscript(navigationController, zendesk: zendesk)
    }

    @Test func handleEscalation_when_logged_out_then_support_form_retains_transcript() async throws {
        // Given
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: nil, email: nil, haveUserIdentity: false)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(
            navigationController: navigationController,
            zendesk: zendesk,
            stores: stores
        )

        // When
        coordinator.handleEscalation(chatID: nil,
                                     transcript: "Test transcript",
                                     supportAreaInfo: makeHighConfidenceSupportAreaInfo(),
                                     entryPoint: .preLogin,
                                     siteAddress: "https://prelogin.example.com")

        // Then
        try await assertSupportFormRetainsTranscript(navigationController, zendesk: zendesk)
        await coordinator.directTicketCreationTask?.value
    }

    @Test func handleEscalation_when_high_confidence_but_no_site_address_then_shows_support_form() async throws {
        // Given
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))

        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(
            navigationController: navigationController,
            zendesk: zendesk,
            stores: stores,
            transcriptConsentPresenter: { _, _, _ in
                Issue.record("Expected missing site address to route directly to the contact form")
            }
        )

        // When
        coordinator.handleEscalation(chatID: nil,
                                     transcript: "Test transcript",
                                     supportAreaInfo: makeHighConfidenceSupportAreaInfo(),
                                     entryPoint: .preLogin)
        await coordinator.directTicketCreationTask?.value

        // Then
        #expect(zendesk.latestInvokedTags.isEmpty)
        #expect(navigationController.viewControllers.contains { $0 is SupportFormHostingController })
        try await assertSupportFormRetainsTranscript(navigationController, zendesk: zendesk)
    }

    @Test func handleEscalation_when_preLogin_has_site_address_then_can_create_ticket_directly_after_transcript_consent() async {
        // Given
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))

        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(
            navigationController: navigationController,
            zendesk: zendesk,
            stores: stores
        )

        // When
        coordinator.handleEscalation(chatID: nil,
                                     transcript: "Test transcript",
                                     supportAreaInfo: makeHighConfidenceSupportAreaInfo(),
                                     entryPoint: .preLogin,
                                     siteAddress: "https://prelogin.example.com")

        // Then
        await coordinator.directTicketCreationTask?.value
        #expect(zendesk.latestInvokedTags.contains("in_app_support_escalate"))
        #expect(zendesk.latestInvokedCustomFields.values.contains("https://prelogin.example.com"))
    }

    @Test func handleEscalation_when_medium_confidence_then_shows_support_form() async throws {
        // Given
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController, zendesk: zendesk)
        let areaInfo = makeMediumConfidenceSupportAreaInfo()

        // When
        coordinator.handleEscalation(chatID: nil, transcript: "Test transcript", supportAreaInfo: areaInfo, entryPoint: .helpAndSupport)
        await coordinator.directTicketCreationTask?.value

        // Then
        #expect(zendesk.latestInvokedTags.isEmpty)
        #expect(navigationController.viewControllers.contains { $0 is SupportFormHostingController })
        try await assertSupportFormRetainsTranscript(navigationController, zendesk: zendesk)
    }

    @Test func handleEscalation_when_low_confidence_then_shows_support_form() async throws {
        // Given
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController, zendesk: zendesk)
        let areaInfo = makeLowConfidenceSupportAreaInfo()

        // When
        coordinator.handleEscalation(chatID: nil, transcript: "Test transcript", supportAreaInfo: areaInfo, entryPoint: .helpAndSupport)
        await coordinator.directTicketCreationTask?.value

        // Then
        #expect(zendesk.latestInvokedTags.isEmpty)
        #expect(navigationController.viewControllers.contains { $0 is SupportFormHostingController })
        try await assertSupportFormRetainsTranscript(navigationController, zendesk: zendesk)
    }

    @Test func handleEscalation_when_transcript_is_whitespace_then_form_has_no_disclosure_or_empty_header() async throws {
        // Given
        let zendesk = MockZendeskManager()
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController, zendesk: zendesk)

        // When
        coordinator.handleEscalation(chatID: nil,
                                     transcript: " \n ",
                                     supportAreaInfo: makeHighConfidenceSupportAreaInfo(),
                                     entryPoint: .helpAndSupport)
        await coordinator.directTicketCreationTask?.value

        // Then
        let viewModel = try #require(supportFormViewModel(from: navigationController))
        #expect(viewModel.shouldShowTranscriptDisclosure == false)
        #expect(viewModel.description.isEmpty)
        viewModel.area = viewModel.areas.first
        viewModel.subject = "Subject"
        viewModel.siteAddress = "https://example.com"
        viewModel.description = "Additional details"
        await viewModel.submitSupportRequest()
        #expect(zendesk.latestSupportRequest?.description == "Additional details")
    }

    @Test func createTicketDirectly_includes_connectivity_diagnostic_and_application_log() async throws {
        // Given
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))
        let diagnostic = ZendeskAttachment(data: Data("Diagnostic".utf8),
                                           filename: "connectivitytest_log.txt",
                                           contentType: "text/plain")
        let attachmentProvider = DefaultSupportRequestAttachmentProvider(
            applicationLogProvider: MockApplicationLogProvider(logs: "Application log")
        )
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(
            navigationController: navigationController,
            additionalAttachmentsProvider: { [diagnostic] },
            attachmentProvider: attachmentProvider,
            zendesk: zendesk
        )

        // When
        coordinator.handleEscalation(chatID: nil,
                                     transcript: "Test transcript",
                                     supportAreaInfo: makeHighConfidenceSupportAreaInfo(),
                                     entryPoint: .helpAndSupport)
        await coordinator.directTicketCreationTask?.value

        // Then
        let request = try #require(zendesk.latestSupportRequest)
        #expect(request.attachments.map(\.filename) == ["connectivitytest_log.txt", "application_log.txt", "mobile_status_report.txt"])
    }

    // MARK: - Ticket Persistence Tests

    @Test func createTicketDirectly_when_succeeds_and_has_chatID_then_dispatches_markTicketCreated() async {
        // Given
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))

        var dispatchedChatID: Int64?
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultSite: Self.makeSite()))
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            if case let .markTicketCreated(chatID, onCompletion) = action {
                dispatchedChatID = chatID
                onCompletion()
            }
        }

        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = SupportEscalationCoordinator(
            navigationController: navigationController,
            zendeskProvider: zendesk,
            stores: stores,
            transcriptConsentPresenter: Self.sendTicketConsentPresenter
        )
        let areaInfo = makeHighConfidenceSupportAreaInfo()

        // When
        coordinator.handleEscalation(chatID: 123, transcript: "Test transcript", supportAreaInfo: areaInfo, entryPoint: .helpAndSupport)
        await coordinator.directTicketCreationTask?.value

        // Then
        #expect(dispatchedChatID == 123)
    }

    @Test func createTicketDirectly_when_succeeds_and_no_chatID_then_does_not_dispatch_markTicketCreated() async {
        // Given
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))

        var markTicketCreatedCalled = false
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultSite: Self.makeSite()))
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            if case .markTicketCreated = action {
                markTicketCreatedCalled = true
            }
        }

        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = SupportEscalationCoordinator(
            navigationController: navigationController,
            zendeskProvider: zendesk,
            stores: stores,
            transcriptConsentPresenter: Self.sendTicketConsentPresenter
        )
        let areaInfo = makeHighConfidenceSupportAreaInfo()

        // When
        coordinator.handleEscalation(chatID: nil, transcript: "Test transcript", supportAreaInfo: areaInfo, entryPoint: .helpAndSupport)
        await coordinator.directTicketCreationTask?.value

        // Then
        #expect(markTicketCreatedCalled == false)
    }

    @Test func createTicketDirectly_when_fails_then_does_not_dispatch_markTicketCreated() async {
        // Given
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .failure(NSError(domain: "Test", code: 500)))

        var markTicketCreatedCalled = false
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultSite: Self.makeSite()))
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            if case .markTicketCreated = action {
                markTicketCreatedCalled = true
            }
        }

        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = SupportEscalationCoordinator(
            navigationController: navigationController,
            zendeskProvider: zendesk,
            stores: stores,
            transcriptConsentPresenter: Self.sendTicketConsentPresenter
        )
        let areaInfo = makeHighConfidenceSupportAreaInfo()

        // When
        coordinator.handleEscalation(chatID: 123, transcript: "Test transcript", supportAreaInfo: areaInfo, entryPoint: .helpAndSupport)
        await coordinator.directTicketCreationTask?.value

        // Then
        #expect(markTicketCreatedCalled == false)
    }

    @Test func createTicketDirectly_when_request_fails_then_fallback_form_retains_same_transcript() async throws {
        // Given
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .failure(NSError(domain: "Test", code: 500)))
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController, zendesk: zendesk)

        // When
        coordinator.handleEscalation(chatID: nil,
                                     transcript: "Test transcript",
                                     supportAreaInfo: makeHighConfidenceSupportAreaInfo(),
                                     entryPoint: .helpAndSupport)
        await coordinator.directTicketCreationTask?.value

        // Then
        try await assertSupportFormRetainsTranscript(navigationController, zendesk: zendesk)
    }

    // MARK: - Analytics Tests

    @Test func createTicketDirectly_when_succeeds_then_tracks_ticketCreated_with_direct_route() async {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController, zendesk: zendesk, analyticsProvider: analyticsProvider)

        // When
        coordinator.handleEscalation(chatID: nil,
                                     transcript: "Test transcript",
                                     supportAreaInfo: makeHighConfidenceSupportAreaInfo(),
                                     entryPoint: .helpAndSupport)
        await coordinator.directTicketCreationTask?.value

        // Then
        assertLastProperties(
            analyticsProvider,
            event: "support_chat_ticket_created",
            include: [
                "route": "direct_ticket_creation",
                "entry_point": "help_and_support",
                "support_area": "mobile-app",
                "support_area_confidence": "high",
                "chat_topic": "woo_mobile_issue_orders"
            ]
        )
    }

    @Test func supportFormCallback_when_succeeds_then_tracks_ticketCreated_with_supportForm_route() async {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController, zendesk: zendesk, analyticsProvider: analyticsProvider)

        coordinator.handleEscalation(chatID: nil,
                                     transcript: "Test transcript",
                                     supportAreaInfo: makeMediumConfidenceSupportAreaInfo(),
                                     entryPoint: .helpAndSupport)
        await coordinator.directTicketCreationTask?.value

        // When
        let viewModel = supportFormViewModel(from: navigationController)
        viewModel?.siteAddress = "https://example.com"
        await viewModel?.submitSupportRequest()

        // Then
        assertLastProperties(
            analyticsProvider,
            event: "support_chat_ticket_created",
            include: [
                "route": "support_form",
                "entry_point": "help_and_support",
                "support_area": "mobile-app",
                "support_area_confidence": "medium"
            ]
        )
    }

    @Test func createTicketDirectly_when_fails_with_identity_error_then_tracks_ticketCreationFailed_with_identity_errorType() async {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .failure(ZendeskError.failedToCreateIdentity))
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController, zendesk: zendesk, analyticsProvider: analyticsProvider)

        // When
        coordinator.handleEscalation(chatID: nil,
                                     transcript: "Test transcript",
                                     supportAreaInfo: makeHighConfidenceSupportAreaInfo(),
                                     entryPoint: .helpAndSupport)
        await coordinator.directTicketCreationTask?.value

        // Then
        assertLastProperties(
            analyticsProvider,
            event: "support_chat_ticket_creation_failed",
            include: [
                "route": "direct_ticket_creation",
                "entry_point": "help_and_support",
                "error_type": "identity_creation_failed"
            ]
        )
    }

    @Test func createTicketDirectly_when_fails_with_generic_error_then_tracks_ticketCreationFailed_with_zendesk_errorType() async {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .failure(NSError(domain: "Test", code: 500)))
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController, zendesk: zendesk, analyticsProvider: analyticsProvider)

        // When
        coordinator.handleEscalation(chatID: nil,
                                     transcript: "Test transcript",
                                     supportAreaInfo: makeHighConfidenceSupportAreaInfo(),
                                     entryPoint: .helpAndSupport)
        await coordinator.directTicketCreationTask?.value

        // Then
        assertLastProperties(
            analyticsProvider,
            event: "support_chat_ticket_creation_failed",
            include: [
                "route": "direct_ticket_creation",
                "entry_point": "help_and_support",
                "error_type": "zendesk_request_failed"
            ]
        )
    }

    @Test func supportFormCallback_when_fails_then_tracks_ticketCreationFailed_with_supportForm_route() async {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .failure(NSError(domain: "Test", code: 500)))
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController, zendesk: zendesk, analyticsProvider: analyticsProvider)

        coordinator.handleEscalation(chatID: nil,
                                     transcript: "Test transcript",
                                     supportAreaInfo: makeMediumConfidenceSupportAreaInfo(),
                                     entryPoint: .helpAndSupport)
        await coordinator.directTicketCreationTask?.value

        // When
        let viewModel = supportFormViewModel(from: navigationController)
        viewModel?.siteAddress = "https://example.com"
        await viewModel?.submitSupportRequest()

        // Then
        assertLastProperties(
            analyticsProvider,
            event: "support_chat_ticket_creation_failed",
            include: [
                "route": "support_form",
                "entry_point": "help_and_support",
                "error_type": "zendesk_request_failed"
            ]
        )
    }
}

// MARK: - Helpers

private extension SupportEscalationCoordinatorTests {
    func makeCoordinator(navigationController: UINavigationController? = nil,
                         additionalAttachmentsProvider: @escaping () -> [ZendeskAttachment] = { [] },
                         attachmentProvider: SupportRequestAttachmentProviding = DefaultSupportRequestAttachmentProvider(),
                         zendesk: MockZendeskManager,
                         analyticsProvider: MockAnalyticsProvider = MockAnalyticsProvider(),
                         stores: StoresManager = MockStoresManager(
                            sessionManager: .makeForTesting(authenticated: true, defaultSite: Site.fake().copy(url: "https://example.com"))
                         ),
                         transcriptConsentPresenter: SupportEscalationCoordinator.TranscriptConsentPresenter? =
                            SupportEscalationCoordinatorTests.sendTicketConsentPresenter) -> SupportEscalationCoordinator {
        SupportEscalationCoordinator(
            navigationController: navigationController,
            additionalAttachmentsProvider: additionalAttachmentsProvider,
            attachmentProvider: attachmentProvider,
            zendeskProvider: zendesk,
            analytics: WooAnalytics(analyticsProvider: analyticsProvider),
            stores: stores,
            transcriptConsentPresenter: transcriptConsentPresenter
        )
    }

    static func sendTicketConsentPresenter(presentingViewController: UIViewController,
                                           onSendTicket: @escaping () -> Void,
                                           onShowContactForm: @escaping () -> Void) {
        onSendTicket()
    }

    static func makeSite(url: String = "https://example.com") -> Site {
        Site.fake().copy(url: url)
    }

    func supportFormViewModel(from navigationController: UINavigationController) -> SupportFormViewModel? {
        navigationController.viewControllers
            .compactMap { $0 as? SupportFormHostingController }
            .first?
            .rootView
            .viewModel
    }

    func assertSupportFormRetainsTranscript(_ navigationController: UINavigationController,
                                            zendesk: MockZendeskManager) async throws {
        let viewModel = try #require(supportFormViewModel(from: navigationController))
        #expect(viewModel.shouldShowTranscriptDisclosure)
        #expect(viewModel.description.isEmpty)
        viewModel.area = viewModel.area ?? viewModel.areas.first
        viewModel.subject = viewModel.subject.isEmpty ? "Subject" : viewModel.subject
        viewModel.siteAddress = viewModel.siteAddress.isEmpty ? "https://example.com" : viewModel.siteAddress
        viewModel.description = "Additional details"
        await viewModel.submitSupportRequest()
        #expect(zendesk.latestSupportRequest?.description == "Additional details\n\n\(expectedFormattedTranscript)")
    }

    var expectedFormattedTranscript: String {
        [SupportEscalationCoordinator.Localization.transcriptHeader, "Test transcript"].joined(separator: "\n\n")
    }

    func assertLastProperties(_ analyticsProvider: MockAnalyticsProvider,
                              event: String,
                              include expectedProperties: [String: Any]) {
        #expect(analyticsProvider.receivedEvents.contains(event))
        guard let properties = analyticsProvider.receivedProperties.last else {
            Issue.record("Expected analytics properties for event \(event)")
            return
        }
        for (key, expectedValue) in expectedProperties {
            #expect((properties[key] as? NSObject) == (expectedValue as? NSObject), "Mismatch for \(key)")
        }
    }

    func makeHighConfidenceSupportAreaInfo() -> SupportAreaInfo {
        SupportAreaInfo(
            areaType: .mobileApp,
            area: SupportFormViewModel.area(for: .mobileApp),
            confidence: .high,
            topic: "woo_mobile_issue_orders"
        )
    }

    func makeMediumConfidenceSupportAreaInfo() -> SupportAreaInfo {
        SupportAreaInfo(
            areaType: .mobileApp,
            area: SupportFormViewModel.area(for: .mobileApp),
            confidence: .medium
        )
    }

    func makeLowConfidenceSupportAreaInfo() -> SupportAreaInfo {
        SupportAreaInfo(
            areaType: .mobileApp,
            area: SupportFormViewModel.area(for: .mobileApp),
            confidence: .low
        )
    }
}
