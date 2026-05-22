import Testing
import UIKit
import Fakes
import Yosemite
@testable import WooCommerce

@MainActor
struct SupportEscalationCoordinatorTests {

    // MARK: - Routing Tests

    @Test func handleEscalation_when_supportAreaInfo_is_nil_then_shows_support_form() {
        // Given
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController, zendesk: zendesk)

        // When
        coordinator.handleEscalation(chatID: nil, transcript: "Test transcript", supportAreaInfo: nil, entryPoint: .helpAndSupport)

        // Then
        #expect(zendesk.latestInvokedTags.isEmpty)
        #expect(navigationController.viewControllers.contains { $0 is SupportFormHostingController })
    }

    @Test func handleEscalation_when_supportAreaInfo_is_nil_and_siteAddress_is_available_then_prefills_siteAddress() {
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
        #expect(viewModel?.siteAddress == "https://prelogin.example.com")
    }

    @Test func handleEscalation_when_high_confidence_and_has_identity_then_creates_ticket_directly_after_transcript_consent() {
        // Given
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))

        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController, zendesk: zendesk)
        let areaInfo = makeHighConfidenceSupportAreaInfo()

        // When
        coordinator.handleEscalation(chatID: nil, transcript: "Test transcript", supportAreaInfo: areaInfo, entryPoint: .helpAndSupport)

        // Then
        #expect(zendesk.latestInvokedTags.contains("in_app_support_escalate"))
        #expect(zendesk.latestInvokedTags.contains("ai_skip"))
        #expect(zendesk.latestInvokedTags.contains("woo_mobile_issue_orders"))
    }

    @Test func handleEscalation_when_high_confidence_and_has_identity_then_asks_for_transcript_consent_before_creating_ticket() {
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

        // Then
        #expect(didAskForConsent)
        #expect(zendesk.latestInvokedTags.isEmpty)
    }

    @Test func handleEscalation_when_transcript_consent_contact_form_selected_then_shows_form_without_prefilled_transcript() {
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

        // Then
        #expect(zendesk.latestInvokedTags.isEmpty)
        let viewModel = supportFormViewModel(from: navigationController)
        #expect(viewModel?.description == "")
        #expect(viewModel?.subject == SupportFormViewModel.subject(for: .mobileApp))
    }

    @Test func handleEscalation_when_transcript_consent_cancelled_then_takes_no_action() {
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

        // Then
        #expect(zendesk.latestInvokedTags.isEmpty)
        #expect(navigationController.viewControllers.contains { $0 is SupportFormHostingController } == false)
    }

    @Test func handleEscalation_when_high_confidence_but_no_identity_then_shows_support_form() {
        // Given
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: nil, email: nil, haveUserIdentity: false)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController, zendesk: zendesk)
        let areaInfo = makeHighConfidenceSupportAreaInfo()

        // When
        coordinator.handleEscalation(chatID: nil, transcript: "Test transcript", supportAreaInfo: areaInfo, entryPoint: .helpAndSupport)

        // Then
        #expect(zendesk.latestInvokedTags.isEmpty)
        #expect(navigationController.viewControllers.contains { $0 is SupportFormHostingController })
    }

    @Test func handleEscalation_when_high_confidence_but_no_site_address_then_shows_support_form() {
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

        // Then
        #expect(zendesk.latestInvokedTags.isEmpty)
        #expect(navigationController.viewControllers.contains { $0 is SupportFormHostingController })
    }

    @Test func handleEscalation_when_preLogin_has_site_address_then_can_create_ticket_directly_after_transcript_consent() {
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
        #expect(zendesk.latestInvokedTags.contains("in_app_support_escalate"))
        #expect(zendesk.latestInvokedCustomFields.values.contains("https://prelogin.example.com"))
    }

    @Test func handleEscalation_when_medium_confidence_then_shows_support_form() {
        // Given
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController, zendesk: zendesk)
        let areaInfo = makeMediumConfidenceSupportAreaInfo()

        // When
        coordinator.handleEscalation(chatID: nil, transcript: "Test transcript", supportAreaInfo: areaInfo, entryPoint: .helpAndSupport)

        // Then
        #expect(zendesk.latestInvokedTags.isEmpty)
        #expect(navigationController.viewControllers.contains { $0 is SupportFormHostingController })
    }

    @Test func handleEscalation_when_low_confidence_then_shows_support_form() {
        // Given
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController, zendesk: zendesk)
        let areaInfo = makeLowConfidenceSupportAreaInfo()

        // When
        coordinator.handleEscalation(chatID: nil, transcript: "Test transcript", supportAreaInfo: areaInfo, entryPoint: .helpAndSupport)

        // Then
        #expect(zendesk.latestInvokedTags.isEmpty)
        #expect(navigationController.viewControllers.contains { $0 is SupportFormHostingController })
    }

    // MARK: - Ticket Persistence Tests

    @Test func createTicketDirectly_when_succeeds_and_has_chatID_then_dispatches_markTicketCreated() {
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

        // Then
        #expect(dispatchedChatID == 123)
    }

    @Test func createTicketDirectly_when_succeeds_and_no_chatID_then_does_not_dispatch_markTicketCreated() {
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

        // Then
        #expect(markTicketCreatedCalled == false)
    }

    @Test func createTicketDirectly_when_fails_then_does_not_dispatch_markTicketCreated() {
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

        // Then
        #expect(markTicketCreatedCalled == false)
    }

    // MARK: - Analytics Tests

    @Test func createTicketDirectly_when_succeeds_then_tracks_ticketCreated_with_direct_route() {
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

    @Test func supportFormCallback_when_succeeds_then_tracks_ticketCreated_with_supportForm_route() {
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

        // When
        let viewModel = supportFormViewModel(from: navigationController)
        viewModel?.siteAddress = "https://example.com"
        viewModel?.submitSupportRequest()

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

    @Test func createTicketDirectly_when_fails_with_identity_error_then_tracks_ticketCreationFailed_with_identity_errorType() {
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

    @Test func createTicketDirectly_when_fails_with_generic_error_then_tracks_ticketCreationFailed_with_zendesk_errorType() {
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

    @Test func supportFormCallback_when_fails_then_tracks_ticketCreationFailed_with_supportForm_route() {
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

        // When
        let viewModel = supportFormViewModel(from: navigationController)
        viewModel?.siteAddress = "https://example.com"
        viewModel?.submitSupportRequest()

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
                         zendesk: MockZendeskManager,
                         analyticsProvider: MockAnalyticsProvider = MockAnalyticsProvider(),
                         stores: StoresManager = MockStoresManager(
                            sessionManager: .makeForTesting(authenticated: true, defaultSite: SupportEscalationCoordinatorTests.makeSite())
                         ),
                         transcriptConsentPresenter: SupportEscalationCoordinator.TranscriptConsentPresenter? =
                            SupportEscalationCoordinatorTests.sendTicketConsentPresenter) -> SupportEscalationCoordinator {
        SupportEscalationCoordinator(
            navigationController: navigationController,
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
            topic: "woo_mobile_issue_orders",
            transcript: "Test transcript"
        )
    }

    func makeMediumConfidenceSupportAreaInfo() -> SupportAreaInfo {
        SupportAreaInfo(
            areaType: .mobileApp,
            area: SupportFormViewModel.area(for: .mobileApp),
            confidence: .medium,
            transcript: "Test transcript"
        )
    }

    func makeLowConfidenceSupportAreaInfo() -> SupportAreaInfo {
        SupportAreaInfo(
            areaType: .mobileApp,
            area: SupportFormViewModel.area(for: .mobileApp),
            confidence: .low,
            transcript: "Test transcript"
        )
    }
}
