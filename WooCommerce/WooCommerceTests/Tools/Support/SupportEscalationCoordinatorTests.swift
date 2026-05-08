import Testing
import UIKit
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
        coordinator.handleEscalation(chatID: nil, transcript: "Test transcript", supportAreaInfo: nil)

        // Then
        #expect(zendesk.latestInvokedTags.isEmpty)
        #expect(navigationController.viewControllers.contains { $0 is SupportFormHostingController })
    }

    @Test func handleEscalation_when_high_confidence_and_has_identity_then_creates_ticket_directly() {
        // Given
        let zendesk = MockZendeskManager()
        zendesk.mockIdentity(name: "Test", email: "test@example.com", haveUserIdentity: true)
        zendesk.whenCreateSupportRequest(thenReturn: .success(()))

        let navigationController = UINavigationController(rootViewController: UIViewController())
        let coordinator = makeCoordinator(navigationController: navigationController, zendesk: zendesk)
        let areaInfo = makeHighConfidenceSupportAreaInfo()

        // When
        coordinator.handleEscalation(chatID: nil, transcript: "Test transcript", supportAreaInfo: areaInfo)

        // Then
        #expect(zendesk.latestInvokedTags.contains("in_app_support_escalate"))
        #expect(zendesk.latestInvokedTags.contains("ai_skip"))
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
        coordinator.handleEscalation(chatID: nil, transcript: "Test transcript", supportAreaInfo: areaInfo)

        // Then
        #expect(zendesk.latestInvokedTags.isEmpty)
        #expect(navigationController.viewControllers.contains { $0 is SupportFormHostingController })
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
        coordinator.handleEscalation(chatID: nil, transcript: "Test transcript", supportAreaInfo: areaInfo)

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
        coordinator.handleEscalation(chatID: nil, transcript: "Test transcript", supportAreaInfo: areaInfo)

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
            stores: stores
        )
        let areaInfo = makeHighConfidenceSupportAreaInfo()

        // When
        coordinator.handleEscalation(chatID: 123, transcript: "Test transcript", supportAreaInfo: areaInfo)

        // Then
        #expect(dispatchedChatID == 123)
    }

    @Test func createTicketDirectly_when_succeeds_and_no_chatID_then_does_not_dispatch_markTicketCreated() {
        // Given
        let zendesk = MockZendeskManager()
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
            stores: stores
        )
        let areaInfo = makeHighConfidenceSupportAreaInfo()

        // When
        coordinator.handleEscalation(chatID: nil, transcript: "Test transcript", supportAreaInfo: areaInfo)

        // Then
        #expect(markTicketCreatedCalled == false)
    }

    @Test func createTicketDirectly_when_fails_then_does_not_dispatch_markTicketCreated() {
        // Given
        let zendesk = MockZendeskManager()
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
            stores: stores
        )
        let areaInfo = makeHighConfidenceSupportAreaInfo()

        // When
        coordinator.handleEscalation(chatID: 123, transcript: "Test transcript", supportAreaInfo: areaInfo)

        // Then
        #expect(markTicketCreatedCalled == false)
    }
}

// MARK: - Helpers

private extension SupportEscalationCoordinatorTests {
    func makeCoordinator(navigationController: UINavigationController? = nil,
                         zendesk: MockZendeskManager) -> SupportEscalationCoordinator {
        SupportEscalationCoordinator(
            navigationController: navigationController,
            zendeskProvider: zendesk
        )
    }

    func makeHighConfidenceSupportAreaInfo() -> SupportAreaInfo {
        SupportAreaInfo(
            areaType: .mobileApp,
            area: SupportFormViewModel.area(for: .mobileApp),
            confidence: .high,
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
