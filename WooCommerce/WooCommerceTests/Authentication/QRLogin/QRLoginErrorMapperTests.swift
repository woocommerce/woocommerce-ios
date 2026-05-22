import Foundation
import Networking
import Testing
@testable import WooCommerce

/// Walks every cell of the spec §8 error catalog through the mapper. Each test
/// names the spec row it covers in its `// Given` comment.
struct QRLoginErrorMapperTests {

    // MARK: - /scan

    @Test func scan_unauthorized_on_both_protocols_maps_to_codeExpired() {
        // §8 row: "Code expired" — fires on 401/403 at scan.
        for proto: QRLoginErrorMapper.Protocol_ in [.selfHosted, .wpCom] {
            let mapped = QRLoginErrorMapper.userFacingError(forScan: .unauthorized, protocol_: proto)
            #expect(mapped.kind == .codeExpired)
            #expect(mapped.primaryAction == .scanAgain)
            #expect(mapped.phase == .scan)
        }
    }

    @Test func scan_self_hosted_404_maps_to_storeUnsupported() {
        // §8 row: "This store can't complete QR login" — self-hosted only,
        // 404 / 426 on /scan or /session-status.
        let mapped = QRLoginErrorMapper.userFacingError(forScan: .notFound, protocol_: .selfHosted)
        #expect(mapped.kind == .storeUnsupported)
        #expect(mapped.primaryAction == .retryFailedPhase)
    }

    @Test func scan_self_hosted_426_maps_to_storeUnsupported() {
        let mapped = QRLoginErrorMapper.userFacingError(forScan: .upgradeRequired, protocol_: .selfHosted)
        #expect(mapped.kind == .storeUnsupported)
    }

    @Test func scan_wpcom_404_maps_to_codeExpired() {
        // §8 wp.com row: 404 on wp.com scan = QR expired before reaching server.
        let mapped = QRLoginErrorMapper.userFacingError(forScan: .notFound, protocol_: .wpCom)
        #expect(mapped.kind == .codeExpired)
        #expect(mapped.primaryAction == .scanAgain)
    }

    @Test func scan_409_maps_to_codeAlreadyUsed() {
        // §8 row: "Code already used" — 409 on /scan, both protocols.
        let mapped = QRLoginErrorMapper.userFacingError(forScan: .conflict, protocol_: .wpCom)
        #expect(mapped.kind == .codeAlreadyUsed)
        #expect(mapped.primaryAction == .scanAgain)
    }

    @Test func scan_429_maps_to_rateLimited_retry() {
        // §8 row: "Too many attempts" — 429 anywhere, retry.
        let mapped = QRLoginErrorMapper.userFacingError(forScan: .rateLimited, protocol_: .selfHosted)
        #expect(mapped.kind == .rateLimited)
        #expect(mapped.primaryAction == .retryFailedPhase)
    }

    @Test func scan_network_maps_to_network_retry() {
        // §8 row: "Couldn't reach your store" — network failure, retry.
        let mapped = QRLoginErrorMapper.userFacingError(forScan: .network, protocol_: .selfHosted)
        #expect(mapped.kind == .network)
        #expect(mapped.primaryAction == .retryFailedPhase)
    }

    @Test func scan_server_error_maps_to_unexpected_retry() {
        // §8 row: "Something went wrong" — 5xx / malformed, retry.
        let mapped = QRLoginErrorMapper.userFacingError(forScan: .internalServerError(code: nil), protocol_: .selfHosted)
        #expect(mapped.kind == .unexpected)
        #expect(mapped.primaryAction == .retryFailedPhase)
    }

    @Test func scan_malformed_maps_to_unexpected() {
        let mapped = QRLoginErrorMapper.userFacingError(forScan: .malformed, protocol_: .wpCom)
        #expect(mapped.kind == .unexpected)
    }

    // MARK: - /session-status (terminal HTTP errors)

    @Test func poll_404_self_hosted_terminal_maps_to_storeUnsupported() {
        let mapped = QRLoginErrorMapper.userFacingError(forPoll: .notFound, protocol_: .selfHosted)
        #expect(mapped?.kind == .storeUnsupported)
    }

    @Test func poll_429_terminal_maps_to_rateLimited() {
        let mapped = QRLoginErrorMapper.userFacingError(forPoll: .rateLimited, protocol_: .wpCom)
        #expect(mapped?.kind == .rateLimited)
    }

    @Test func poll_wpcom_403_token_hash_mismatch_maps_to_codeExpired_scan_again() {
        // §5.2.2 wp.com: 403 = token_hash mismatch, terminal, "Code expired".
        let mapped = QRLoginErrorMapper.userFacingError(forPoll: .unauthorized, protocol_: .wpCom)
        #expect(mapped?.kind == .codeExpired)
        #expect(mapped?.primaryAction == .scanAgain)
    }

    @Test func poll_transient_errors_return_nil_so_loop_can_absorb_them() {
        // §5.1.2 / §5.2.2: 5xx / malformed / network → transient; the polling
        // loop's 4-strike threshold decides when to surface.
        #expect(QRLoginErrorMapper.userFacingError(forPoll: .network, protocol_: .selfHosted) == nil)
        #expect(QRLoginErrorMapper.userFacingError(forPoll: .internalServerError(code: nil), protocol_: .wpCom) == nil)
        #expect(QRLoginErrorMapper.userFacingError(forPoll: .malformed, protocol_: .selfHosted) == nil)
    }

    @Test func poll_after_threshold_network_maps_to_network_retry() {
        let mapped = QRLoginErrorMapper.userFacingError(forPollAfterThreshold: .network)
        #expect(mapped.kind == .network)
        #expect(mapped.primaryAction == .retryFailedPhase)
    }

    @Test func poll_after_threshold_server_error_maps_to_unexpected_retry() {
        let mapped = QRLoginErrorMapper.userFacingError(forPollAfterThreshold: .serverError(status: 503))
        #expect(mapped.kind == .unexpected)
        #expect(mapped.primaryAction == .retryFailedPhase)
    }

    // MARK: - Terminal poll states

    @Test func terminal_rejected_maps_to_signInDenied() {
        // §8 row: "Sign-in denied".
        let mapped = QRLoginErrorMapper.userFacingError(forTerminalState: .rejected, protocol_: .selfHosted)
        #expect(mapped?.kind == .signInDenied)
    }

    @Test func terminal_expired_maps_to_signInTimedOut() {
        // §8 row: "Sign-in timed out".
        let mapped = QRLoginErrorMapper.userFacingError(forTerminalState: .expired, protocol_: .wpCom)
        #expect(mapped?.kind == .signInTimedOut)
    }

    @Test func terminal_unknown_state_maps_to_signInTimedOut_defensively() {
        // Spec §5.1.2 / §5.2.2: unknown state → treated defensively as expired.
        let mapped = QRLoginErrorMapper.userFacingError(forTerminalState: .unknown, protocol_: .selfHosted)
        #expect(mapped?.kind == .signInTimedOut)
    }

    @Test func terminal_consumed_maps_to_alreadySignedInElsewhere() {
        // §8 wp.com row: "Already signed in elsewhere".
        let mapped = QRLoginErrorMapper.userFacingError(forTerminalState: .consumed, protocol_: .wpCom)
        #expect(mapped?.kind == .alreadySignedInElsewhere)
    }

    @Test func non_terminal_states_return_nil() {
        #expect(QRLoginErrorMapper.userFacingError(forTerminalState: .scanned, protocol_: .selfHosted) == nil)
        #expect(QRLoginErrorMapper.userFacingError(forTerminalState: .approved(exchangeGrant: "g"), protocol_: .wpCom) == nil)
    }

    // MARK: - /exchange

    @Test func exchange_unauthorized_maps_to_codeExpired() {
        let mapped = QRLoginErrorMapper.userFacingError(forExchange: .unauthorized, protocol_: .selfHosted)
        #expect(mapped.kind == .codeExpired)
        #expect(mapped.primaryAction == .scanAgain)
    }

    @Test func exchange_self_hosted_404_maps_to_storeUnsupported() {
        let mapped = QRLoginErrorMapper.userFacingError(forExchange: .notFound, protocol_: .selfHosted)
        #expect(mapped.kind == .storeUnsupported)
    }

    @Test func exchange_wpcom_404_maps_to_signInInterrupted() {
        // §8 wp.com row: 404 on wp.com exchange → "Sign-in interrupted".
        let mapped = QRLoginErrorMapper.userFacingError(forExchange: .notFound, protocol_: .wpCom)
        #expect(mapped.kind == .signInInterrupted)
        #expect(mapped.primaryAction == .scanAgain)
    }

    @Test func exchange_412_qr_login_not_approved_maps_to_signInTimedOut() {
        // §8 row: "Sign-in timed out".
        let mapped = QRLoginErrorMapper.userFacingError(
            forExchange: .preconditionFailed(code: "qr_login_not_approved"),
            protocol_: .selfHosted
        )
        #expect(mapped.kind == .signInTimedOut)
        #expect(mapped.primaryAction == .scanAgain)
    }

    @Test func exchange_412_invalid_exchange_grant_maps_to_signInInterrupted() {
        // §8 row: "Sign-in interrupted".
        let mapped = QRLoginErrorMapper.userFacingError(
            forExchange: .preconditionFailed(code: "invalid_exchange_grant"),
            protocol_: .selfHosted
        )
        #expect(mapped.kind == .signInInterrupted)
    }

    @Test func exchange_412_unknown_code_maps_to_unexpected() {
        // §8 row: "Something went wrong" — 412 with a body code we don't
        // recognise.
        let mapped = QRLoginErrorMapper.userFacingError(
            forExchange: .preconditionFailed(code: "some_other_code"),
            protocol_: .selfHosted
        )
        #expect(mapped.kind == .unexpected)
        #expect(mapped.primaryAction == .retryFailedPhase)
    }

    @Test func exchange_wpcom_500_already_consumed_maps_to_alreadySignedInElsewhere() {
        // §8 wp.com row: 500 `already_consumed` on exchange.
        let mapped = QRLoginErrorMapper.userFacingError(
            forExchange: .internalServerError(code: "already_consumed"),
            protocol_: .wpCom
        )
        #expect(mapped.kind == .alreadySignedInElsewhere)
        #expect(mapped.primaryAction == .scanAgain)
    }

    @Test func exchange_self_hosted_500_already_consumed_falls_through_to_unexpected() {
        // §8 note: self-hosted protocol can't distinguish "already signed in
        // elsewhere" from generic server failures, so a self-hosted 500
        // (even with a body code) does not surface that variant.
        let mapped = QRLoginErrorMapper.userFacingError(
            forExchange: .internalServerError(code: "already_consumed"),
            protocol_: .selfHosted
        )
        #expect(mapped.kind == .unexpected)
    }

    @Test func exchange_429_maps_to_rateLimited_retry() {
        let mapped = QRLoginErrorMapper.userFacingError(forExchange: .rateLimited, protocol_: .wpCom)
        #expect(mapped.kind == .rateLimited)
        #expect(mapped.primaryAction == .retryFailedPhase)
    }

    @Test func exchange_network_maps_to_network_retry() {
        let mapped = QRLoginErrorMapper.userFacingError(forExchange: .network, protocol_: .selfHosted)
        #expect(mapped.kind == .network)
        #expect(mapped.primaryAction == .retryFailedPhase)
    }
}
