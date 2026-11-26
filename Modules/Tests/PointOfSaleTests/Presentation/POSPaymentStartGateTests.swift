import Testing
@testable import PointOfSale

@Suite(.timeLimit(.minutes(5)))
@MainActor
struct POSPaymentStartGateTests {
    @Test
    func test_run_closes_gate_until_start_returns() async {
        // Given
        let sut = POSPaymentStartGate()

        // When
        let task = sut.run({}, isCardStartPending: false)

        // Then
        #expect(sut.isClosed(isCardStartPending: false))
        #expect(sut.run({}, isCardStartPending: false) == nil)
        await task?.value
        #expect(!sut.isClosed(isCardStartPending: false))
    }

    @Test
    func test_run_blocks_another_start_while_reader_work_is_pending_after_return() async {
        // Given
        let sut = POSPaymentStartGate()
        await sut.run({}, isCardStartPending: false)?.value

        // Then
        #expect(sut.isClosed(isCardStartPending: true))
        #expect(sut.run({}, isCardStartPending: true) == nil)

        // When reader work ends
        #expect(!sut.isClosed(isCardStartPending: false))
        let nextStart = sut.run({}, isCardStartPending: false)
        #expect(nextStart != nil)
        await nextStart?.value
    }

    @Test
    func test_release_does_not_open_gate_when_reader_work_is_pending() async {
        // Given
        let sut = POSPaymentStartGate()
        let task = sut.run({}, isCardStartPending: false)

        // When
        sut.release(isStillPending: true)

        // Then
        #expect(sut.isClosed(isCardStartPending: false))
        await task?.value
    }

    @Test
    func test_run_when_earlier_start_returns_after_a_newer_start_then_gate_stays_closed() async {
        // Given
        let sut = POSPaymentStartGate()
        var finishFirstStart: CheckedContinuation<Void, Never>?
        var finishSecondStart: CheckedContinuation<Void, Never>?
        var firstStart: Task<Void, Never>?
        var secondStart: Task<Void, Never>?
        await fireOnce { fire in
            firstStart = sut.run({
                await withCheckedContinuation { continuation in
                    finishFirstStart = continuation
                    fire()
                }
            }, isCardStartPending: false)
        }
        sut.release(isStillPending: false)

        // When
        await fireOnce { fire in
            secondStart = sut.run({
                await withCheckedContinuation { continuation in
                    finishSecondStart = continuation
                    fire()
                }
            }, isCardStartPending: false)
        }
        finishFirstStart?.resume()
        await firstStart?.value

        // Then
        #expect(sut.isClosed(isCardStartPending: false))
        finishSecondStart?.resume()
        await secondStart?.value
        #expect(!sut.isClosed(isCardStartPending: false))
    }
}
