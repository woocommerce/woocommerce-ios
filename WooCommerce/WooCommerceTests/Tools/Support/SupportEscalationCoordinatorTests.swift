import XCTest
import Yosemite
@testable import WooCommerce

@MainActor
final class SupportEscalationCoordinatorTests: XCTestCase {

    private var zendesk: MockZendeskManager!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        zendesk = MockZendeskManager()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        zendesk = nil
        analyticsProvider = nil
        analytics = nil
        super.tearDown()
    }

    // MARK: - Routing Tests

    func test_handleEscalation_when_supportAreaInfo_is_nil_then_shows_support_form() {
        // Given
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController)

        // When
        coordinator.handleEscalation(chatID: nil, transcript: "Test transcript", supportAreaInfo: nil)

        // Then - createSupportRequest should not be called, support form should be pushed
        XCTAssertTrue(zendesk.latestInvokedTags.isEmpty)
        XCTAssertTrue(navigationController.viewControllers.contains { $0 is SupportFormHostingController })
    }

    func test_handleEscalation_when_high_confidence_and_has_identity_then_creates_ticket_directly() {
        // Given
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))

        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController)
        let areaInfo = makeHighConfidenceSupportAreaInfo()

        // When
        coordinator.handleEscalation(chatID: nil, transcript: "Test transcript", supportAreaInfo: areaInfo)

        // Then - createSupportRequest should be called with expected tags
        XCTAssertTrue(zendesk.latestInvokedTags.contains("in_app_support_escalate"))
        XCTAssertTrue(zendesk.latestInvokedTags.contains("ai_skip"))
    }

    func test_handleEscalation_when_high_confidence_but_no_identity_then_shows_support_form() {
        // Given
        zendesk.mockIdentity(name: nil, email: nil, haveUserIdentity: false)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController)
        let areaInfo = makeHighConfidenceSupportAreaInfo()

        // When
        coordinator.handleEscalation(chatID: nil, transcript: "Test transcript", supportAreaInfo: areaInfo)

        // Then - createSupportRequest should not be called, support form should be pushed
        XCTAssertTrue(zendesk.latestInvokedTags.isEmpty)
        XCTAssertTrue(navigationController.viewControllers.contains { $0 is SupportFormHostingController })
    }

    func test_handleEscalation_when_medium_confidence_then_shows_support_form() {
        // Given
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController)
        let areaInfo = makeMediumConfidenceSupportAreaInfo()

        // When
        coordinator.handleEscalation(chatID: nil, transcript: "Test transcript", supportAreaInfo: areaInfo)

        // Then - createSupportRequest should not be called, support form should be pushed
        XCTAssertTrue(zendesk.latestInvokedTags.isEmpty)
        XCTAssertTrue(navigationController.viewControllers.contains { $0 is SupportFormHostingController })
    }

    func test_handleEscalation_when_low_confidence_then_shows_support_form() {
        // Given
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController)
        let areaInfo = makeLowConfidenceSupportAreaInfo()

        // When
        coordinator.handleEscalation(chatID: nil, transcript: "Test transcript", supportAreaInfo: areaInfo)

        // Then - createSupportRequest should not be called, support form should be pushed
        XCTAssertTrue(zendesk.latestInvokedTags.isEmpty)
        XCTAssertTrue(navigationController.viewControllers.contains { $0 is SupportFormHostingController })
    }

    // MARK: - Analytics Tests

    func test_createTicketDirectly_when_succeeds_then_tracks_supportNewRequestCreated() {
        // Given
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))

        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController)
        let areaInfo = makeHighConfidenceSupportAreaInfo()

        // When
        coordinator.handleEscalation(chatID: nil, transcript: "Test transcript", supportAreaInfo: areaInfo)

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("support_new_request_created"))
    }

    func test_createTicketDirectly_when_fails_then_tracks_supportNewRequestFailed() {
        // Given
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .failure(NSError(domain: "Test", code: 500)))

        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController)
        let areaInfo = makeHighConfidenceSupportAreaInfo()

        // When
        coordinator.handleEscalation(chatID: nil, transcript: "Test transcript", supportAreaInfo: areaInfo)

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains("support_new_request_failed"))
    }

    // MARK: - Ticket Persistence Tests

    func test_createTicketDirectly_when_succeeds_and_has_chatID_then_dispatches_markTicketCreated() {
        // Given
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))

        var dispatchedChatID: Int64?
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
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
            analytics: analytics,
            stores: stores
        )
        let areaInfo = makeHighConfidenceSupportAreaInfo()

        // When
        coordinator.handleEscalation(chatID: 123, transcript: "Test transcript", supportAreaInfo: areaInfo)

        // Then
        XCTAssertEqual(dispatchedChatID, 123)
    }

    func test_createTicketDirectly_when_succeeds_and_no_chatID_then_does_not_dispatch_markTicketCreated() {
        // Given
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))

        var markTicketCreatedCalled = false
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            if case .markTicketCreated = action {
                markTicketCreatedCalled = true
            }
        }

        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = SupportEscalationCoordinator(
            navigationController: navigationController,
            zendeskProvider: zendesk,
            analytics: analytics,
            stores: stores
        )
        let areaInfo = makeHighConfidenceSupportAreaInfo()

        // When
        coordinator.handleEscalation(chatID: nil, transcript: "Test transcript", supportAreaInfo: areaInfo)

        // Then
        XCTAssertFalse(markTicketCreatedCalled)
    }

    func test_createTicketDirectly_when_fails_then_does_not_dispatch_markTicketCreated() {
        // Given
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .failure(NSError(domain: "Test", code: 500)))

        var markTicketCreatedCalled = false
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.whenReceivingAction(ofType: SupportChatAction.self) { action in
            if case .markTicketCreated = action {
                markTicketCreatedCalled = true
            }
        }

        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = SupportEscalationCoordinator(
            navigationController: navigationController,
            zendeskProvider: zendesk,
            analytics: analytics,
            stores: stores
        )
        let areaInfo = makeHighConfidenceSupportAreaInfo()

        // When
        coordinator.handleEscalation(chatID: 123, transcript: "Test transcript", supportAreaInfo: areaInfo)

        // Then
        XCTAssertFalse(markTicketCreatedCalled)
    }

    // MARK: - Request Content Tests

    func test_createTicketDirectly_uses_first_user_message_as_description() {
        // Given
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))

        var capturedRequest: ZendeskSupportRequest?
        let capturingZendesk = CapturingZendeskManager { request in
            capturedRequest = request
        }

        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = SupportEscalationCoordinator(
            navigationController: navigationController,
            zendeskProvider: capturingZendesk,
            analytics: analytics
        )

        let areaInfo = SupportAreaInfo(
            areaType: .mobileApp,
            area: SupportFormViewModel.area(for: .mobileApp),
            confidence: .high,
            transcript: "Full transcript here",
            firstUserMessage: "My app keeps crashing"
        )

        // When
        coordinator.handleEscalation(chatID: nil, transcript: "Full transcript", supportAreaInfo: areaInfo)

        // Then
        XCTAssertEqual(capturedRequest?.description, "My app keeps crashing")
    }

    func test_createTicketDirectly_uses_area_based_subject() {
        // Given
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)

        var capturedRequest: ZendeskSupportRequest?
        let capturingZendesk = CapturingZendeskManager { request in
            capturedRequest = request
        }

        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = SupportEscalationCoordinator(
            navigationController: navigationController,
            zendeskProvider: capturingZendesk,
            analytics: analytics
        )

        let areaInfo = SupportAreaInfo(
            areaType: .cardReader,
            area: SupportFormViewModel.area(for: .cardReader),
            confidence: .high,
            transcript: "Transcript",
            firstUserMessage: "Card reader issue"
        )

        // When
        coordinator.handleEscalation(chatID: nil, transcript: "Transcript", supportAreaInfo: areaInfo)

        // Then
        XCTAssertEqual(capturedRequest?.subject, "Card Reader Support Request")
    }
}

// MARK: - Helpers

private extension SupportEscalationCoordinatorTests {
    func makeCoordinator(navigationController: UINavigationController? = nil) -> SupportEscalationCoordinator {
        SupportEscalationCoordinator(
            navigationController: navigationController,
            zendeskProvider: zendesk,
            analytics: analytics
        )
    }

    func makeHighConfidenceSupportAreaInfo() -> SupportAreaInfo {
        SupportAreaInfo(
            areaType: .mobileApp,
            area: SupportFormViewModel.area(for: .mobileApp),
            confidence: .high,
            transcript: "Test transcript",
            firstUserMessage: "Help me"
        )
    }

    func makeMediumConfidenceSupportAreaInfo() -> SupportAreaInfo {
        SupportAreaInfo(
            areaType: .mobileApp,
            area: SupportFormViewModel.area(for: .mobileApp),
            confidence: .medium,
            transcript: "Test transcript",
            firstUserMessage: "Help me"
        )
    }

    func makeLowConfidenceSupportAreaInfo() -> SupportAreaInfo {
        SupportAreaInfo(
            areaType: .mobileApp,
            area: SupportFormViewModel.area(for: .mobileApp),
            confidence: .low,
            transcript: "Test transcript",
            firstUserMessage: "Help me"
        )
    }
}

// MARK: - Capturing Mock

private final class CapturingZendeskManager: ZendeskManagerProtocol {
    let zendeskEnabled = true
    let haveUserIdentity = true

    private let onCreateRequest: (ZendeskSupportRequest) -> Void

    init(onCreateRequest: @escaping (ZendeskSupportRequest) -> Void) {
        self.onCreateRequest = onCreateRequest
    }

    func createSupportRequest(_ request: ZendeskSupportRequest, onCompletion: @escaping (Result<Void, Error>) -> Void) {
        onCreateRequest(request)
        onCompletion(.success(()))
    }

    func retrieveUserInfoIfAvailable() -> (name: String?, emailAddress: String?) { (nil, nil) }
    func createIdentity(name: String, email: String) async throws {}
    func createIdentity(presentIn viewController: UIViewController, completion: @escaping (Bool) -> Void) {}
    func showHelpCenter(from controller: UIViewController) {}
    func showSupportEmailPrompt(from controller: UIViewController, completion: @escaping onUserInformationCompletion) {}
    func initialize() {}
    func reset() {}
}
