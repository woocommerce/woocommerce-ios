import Foundation
import Testing
@testable import PointOfSale

/// Approvals follow the capabilities a PIN carries; names and presets never grant or deny access.
@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSCapabilityApprovalTests {
    @Test func test_gate_when_operator_named_cashier_holds_capability_then_performs_without_approval() async throws {
        // Given
        let sut = try await makeSUT(operator: POSStaff(displayName: "Cashier", capabilities: [.processSales, .issueRefunds]))
        var results: [Bool] = []

        // When
        sut.handler.gate(.issueRefunds, reason: "Refund") { results.append($0) }

        // Then
        #expect(results == [false])
        #expect(sut.handler.request == nil)
    }

    @Test func test_gate_when_operator_named_admin_lacks_capability_then_requires_approval() async throws {
        // Given
        let sut = try await makeSUT(operator: POSStaff(displayName: "Admin", capabilities: [.processSales, .manageStoreSettings]))
        var results: [Bool] = []

        // When
        sut.handler.gate(.exitPOS, reason: "Exit") { results.append($0) }

        // Then
        #expect(results.isEmpty)
        #expect(sut.handler.request?.capability == .exitPOS)
        sut.handler.cancel()
    }

    @Test func test_gate_when_approver_holds_only_required_capability_then_performs_once_without_changing_operator() async throws {
        // Given
        let operatorStaff = POSStaff(displayName: "Admin", capabilities: [.processSales])
        let approver = POSStaff(displayName: "Cashier", capabilities: [.exitPOS])
        let sut = try await makeSUT(operator: operatorStaff, approver: approver)
        var results: [Bool] = []
        sut.handler.gate(.exitPOS, reason: "Exit") { results.append($0) }

        // When
        #expect(await sut.handler.submit(pin: Constants.approverPIN))

        // Then
        #expect(results == [true])
        #expect(sut.session.currentStaff == operatorStaff)
        #expect(!sut.session.allows(.exitPOS))
        sut.handler.gate(.exitPOS, reason: "Exit") { results.append($0) }
        #expect(results == [true])
        #expect(sut.handler.request?.capability == .exitPOS)
        sut.handler.cancel()
    }

    @Test func test_gate_when_approver_lacks_required_capability_then_keeps_request_without_performing() async throws {
        // Given
        let sut = try await makeSUT(operator: POSStaff(displayName: "Cashier", capabilities: [.processSales]),
                                    approver: POSStaff(displayName: "Admin", capabilities: [.exitPOS, .manageStoreSettings]))
        var results: [Bool] = []
        sut.handler.gate(.issueRefunds, reason: "Refund") { results.append($0) }

        // When
        #expect(await sut.handler.submit(pin: Constants.approverPIN) == false)

        // Then
        #expect(results.isEmpty)
        #expect(sut.handler.pinEntryState == .error(kind: .invalidPIN))
        #expect(sut.handler.request?.capability == .issueRefunds)
        sut.handler.cancel()
    }

    @Test func test_gate_when_pos_locks_and_unlocks_before_approval_then_does_not_perform() async throws {
        // Given
        let operatorStaff = POSStaff(displayName: "Cashier", capabilities: [.processSales])
        let sut = try await makeSUT(operator: operatorStaff,
                                    approver: POSStaff(displayName: "Manager", capabilities: [.issueRefunds]))
        var results: [Bool] = []
        sut.handler.gate(.issueRefunds, reason: "Refund") { results.append($0) }

        // When
        sut.session.lock()
        try await sut.session.signIn(withPIN: Constants.operatorPIN)
        _ = await sut.handler.submit(pin: Constants.approverPIN)

        // Then
        #expect(results.isEmpty)
        #expect(sut.session.currentStaff == operatorStaff)
        sut.handler.cancel()
    }

    @Test func test_gate_when_pos_locks_during_verification_then_does_not_perform() async {
        // Given
        let session = MockPOSAccessSession(currentStaff: POSStaff(displayName: "Staff", capabilities: [.processSales]))
        let handler = POSManagerOverrideHandler(session: session)
        var results: [Bool] = []
        session.onManagerApproval = {
            session.lock()
            session.isLocked = false
        }
        handler.gate(.createCoupons, reason: "Coupon") { results.append($0) }

        // When
        _ = await handler.submit(pin: Constants.approverPIN)

        // Then
        #expect(session.managerApprovalCapabilities == [.createCoupons])
        #expect(results.isEmpty)
        handler.cancel()
    }
}

private extension POSCapabilityApprovalTests {
    enum Constants {
        static let operatorPIN = "1111"
        static let approverPIN = "2222"
    }

    struct SUT {
        let session: DefaultPOSAccessSession
        let handler: POSManagerOverrideHandler
        let defaultsScope: CapabilityApprovalTestDefaults
    }

    func makeSUT(operator operatorStaff: POSStaff, approver: POSStaff? = nil) async throws -> SUT {
        var credentials = [try credential(operatorStaff, pin: Constants.operatorPIN)]
        if let approver {
            credentials.append(try credential(approver, pin: Constants.approverPIN))
        }
        let provider = MockPOSPINCredentialProvider(credentialsResult: .success(credentials))
        let defaultsScope = CapabilityApprovalTestDefaults()
        let session = DefaultPOSAccessSession(
            siteID: 123,
            authenticator: DefaultPOSPINAuthenticator(credentialProvider: provider),
            rateLimiter: POSLocalRateLimiter(siteID: 123, storage: InMemoryPOSSecureStorage(), clock: MockPOSPINClock()),
            credentialProvider: provider,
            userDefaults: defaultsScope.defaults
        )
        try await session.signIn(withPIN: Constants.operatorPIN)
        return SUT(session: session, handler: POSManagerOverrideHandler(session: session), defaultsScope: defaultsScope)
    }

    func credential(_ staff: POSStaff, pin: String) throws -> POSPINCredential {
        POSPINCredential(staff: staff, pinHash: try #require(POSPINHash(pin: pin, iterations: 1)))
    }
}

private final class CapabilityApprovalTestDefaults {
    let defaults: UserDefaults
    private let name = "POSCapabilityApprovalTests.\(UUID().uuidString)"
    init() { defaults = UserDefaults(suiteName: name)! }
    deinit { defaults.removePersistentDomain(forName: name) }
}
