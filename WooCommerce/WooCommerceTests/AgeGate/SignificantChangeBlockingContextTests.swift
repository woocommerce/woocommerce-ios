import Testing
@testable import WooCommerce

struct SignificantChangeBlockingContextTests {
    @Test func test_offersContactSupport_when_access_is_blocked_then_is_true() {
        // Given
        let blockingContexts: [SignificantChangeBlockingContext] = [.approvalNeeded, .pendingApproval, .approvalDenied]

        // Then
        for context in blockingContexts {
            #expect(context.offersContactSupport, "\(context) should offer Contact Support")
        }
    }

    @Test func test_offersContactSupport_when_approval_granted_then_is_false() {
        // Given
        let context = SignificantChangeBlockingContext.approvalGranted

        // Then
        #expect(context.offersContactSupport == false)
    }
}
