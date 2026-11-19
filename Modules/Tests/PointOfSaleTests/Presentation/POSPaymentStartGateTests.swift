import Testing
import Observation
@testable import PointOfSale

@Suite(.timeLimit(.minutes(5)))
@MainActor
struct POSPaymentStartGateTests {
    @Test
    func test_run_when_start_returns_with_nothing_pending_then_gate_opens() async {
        // Given
        let sut = POSPaymentStartGate()

        // When
        let task = sut.run({}, isStillPending: { false })
        #expect(sut.isStarting)
        await task?.value

        // Then
        #expect(!sut.isStarting)
    }

    @Test
    func test_run_when_gate_is_closed_then_second_start_does_not_run() async {
        // Given
        let sut = POSPaymentStartGate()
        var startCount = 0
        let work = PendingWork()
        work.isPending = true
        let firstStart = sut.run({ startCount += 1 }, isStillPending: { work.isPending })

        // When
        let secondStart = sut.run({ startCount += 1 }, isStillPending: { false })

        // Then
        #expect(secondStart == nil)
        #expect(sut.isStarting)

        work.isPending = false
        await firstStart?.value
        #expect(startCount == 1)
    }

    @Test
    func test_run_when_start_leaves_work_pending_then_gate_opens_once_the_work_ends() async {
        // Given
        let sut = POSPaymentStartGate()
        let work = PendingWork()

        // When
        var task: Task<Void, Never>?
        await fireOnce { fire in
            task = sut.run({
                work.isPending = true
                fire()
            }, isStillPending: { work.isPending })
        }
        sut.release(isStillPending: work.isPending)

        // Then
        #expect(sut.isStarting)

        // When
        work.isPending = false
        await task?.value

        // Then
        #expect(!sut.isStarting)
    }

    @Test
    func test_run_when_pending_work_ends_right_after_start_returns_then_gate_opens_and_next_start_runs() async {
        // Given
        let sut = POSPaymentStartGate()
        let work = PendingWork()
        var startCount = 0

        // When the work fails in the same turn it was started, before anything can observe it as pending
        await sut.run({
            startCount += 1
            work.isPending = true
            Task { @MainActor in
                work.isPending = false
            }
        }, isStillPending: { work.isPending })?.value

        // Then
        #expect(!sut.isStarting)

        // When
        await sut.run({ startCount += 1 }, isStillPending: { work.isPending })?.value

        // Then
        #expect(startCount == 2)
    }

    @Test
    func test_run_when_earlier_start_returns_after_a_newer_start_then_gate_stays_closed() async {
        // Given
        let sut = POSPaymentStartGate()
        var finishFirstStart: CheckedContinuation<Void, Never>?
        let secondWork = PendingWork()
        secondWork.isPending = true
        var firstStart: Task<Void, Never>?
        await fireOnce { fire in
            firstStart = sut.run({
                await withCheckedContinuation { continuation in
                    finishFirstStart = continuation
                    fire()
                }
            }, isStillPending: { false })
        }
        sut.release(isStillPending: false)

        // When
        let secondStart = sut.run({}, isStillPending: { secondWork.isPending })
        finishFirstStart?.resume()
        await firstStart?.value

        // Then
        #expect(sut.isStarting)

        // When
        secondWork.isPending = false
        await secondStart?.value

        // Then
        #expect(!sut.isStarting)
    }

    @Test
    func test_run_after_gate_opened_then_next_start_runs() async {
        // Given
        let sut = POSPaymentStartGate()
        var startCount = 0
        await sut.run({ startCount += 1 }, isStillPending: { false })?.value

        // When
        await sut.run({ startCount += 1 }, isStillPending: { false })?.value

        // Then
        #expect(startCount == 2)
        #expect(!sut.isStarting)
    }
}

@MainActor
@Observable
private final class PendingWork {
    var isPending = false
}
