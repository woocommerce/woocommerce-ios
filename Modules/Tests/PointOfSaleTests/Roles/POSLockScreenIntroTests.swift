import Testing
@testable import PointOfSale

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct POSLockScreenIntroTests {
    @Test func test_run_when_callers_overlap_then_shares_one_animation_sequence() async throws {
        // Given
        let sleeper = ControlledSleeper()
        let sut = POSLockScreenIntro(sleep: sleeper.sleep)
        defer {
            sut.cancel()
            sleeper.finish()
        }
        var sleeps = sleeper.calls.makeAsyncIterator()
        let starts = AsyncStream<Void>.makeStream()
        var started = starts.stream.makeAsyncIterator()

        // When
        let callers = (0..<4).map { _ in
            Task { @MainActor in
                starts.continuation.yield(())
                await sut.run(shouldAnimate: true)
            }
        }
        for _ in callers {
            _ = await started.next()
        }
        starts.continuation.finish()
        try await expectSleep(.milliseconds(80), from: &sleeps)

        // Then
        #expect(sut.phase == .appearing)
        try #require(sleeper.durations.count == 1)
        sleeper.resumeNext()
        try await expectSleep(.seconds(0.2), from: &sleeps)
        #expect(sut.phase == .closing)
        sleeper.resumeNext()
        try await expectSleep(.seconds(0.28), from: &sleeps)
        #expect(sut.phase == .revealing)
        sleeper.resumeNext()
        for caller in callers {
            await caller.value
        }
        #expect(sut.phase == .finished)
        #expect(sleeper.durations == [.milliseconds(80), .seconds(0.2), .seconds(0.28)])
    }

    @Test func test_run_when_one_caller_is_cancelled_then_shared_sequence_continues() async throws {
        // Given
        let sleeper = ControlledSleeper()
        let sut = POSLockScreenIntro(sleep: sleeper.sleep)
        defer {
            sut.cancel()
            sleeper.finish()
        }
        var sleeps = sleeper.calls.makeAsyncIterator()
        let first = Task { await sut.run(shouldAnimate: true) }
        try await expectSleep(.milliseconds(80), from: &sleeps)
        let starts = AsyncStream<Void>.makeStream()
        var started = starts.stream.makeAsyncIterator()

        // When
        first.cancel()
        let replacement = Task { @MainActor in
            starts.continuation.yield(())
            await sut.run(shouldAnimate: true)
        }
        _ = await started.next()
        starts.continuation.finish()

        // Then
        #expect(sut.phase == .appearing)
        try #require(sleeper.durations.count == 1)
        sleeper.resumeNext()
        try await expectSleep(.seconds(0.2), from: &sleeps)
        #expect(sut.phase == .closing)
        sleeper.resumeNext()
        try await expectSleep(.seconds(0.28), from: &sleeps)
        #expect(sut.phase == .revealing)
        sleeper.resumeNext()
        await first.value
        await replacement.value
        #expect(sut.phase == .finished)
        #expect(sleeper.durations.count == 3)
    }

    @Test(arguments: [POSLockScreenIntro.Phase.appearing, .closing, .revealing])
    func test_cancel_when_sequence_is_active_then_finishes_without_advancing(phase: POSLockScreenIntro.Phase) async throws {
        // Given
        let sleeper = ControlledSleeper()
        let sut = POSLockScreenIntro(sleep: sleeper.sleep)
        defer {
            sut.cancel()
            sleeper.finish()
        }
        var sleeps = sleeper.calls.makeAsyncIterator()
        let caller = Task { await sut.run(shouldAnimate: true) }
        try await expectSleep(.milliseconds(80), from: &sleeps)
        if phase != .appearing {
            sleeper.resumeNext()
            try await expectSleep(.seconds(0.2), from: &sleeps)
        }
        if phase == .revealing {
            sleeper.resumeNext()
            try await expectSleep(.seconds(0.28), from: &sleeps)
        }
        try #require(sut.phase == phase)
        let countBeforeCancellation = sleeper.durations.count

        // When
        sut.cancel()

        // Then
        #expect(sut.phase == .finished)
        sleeper.resumeNext()
        await caller.value
        #expect(sut.phase == .finished)
        #expect(sleeper.durations.count == countBeforeCancellation)
    }

    @Test func test_run_when_animation_is_disabled_then_finishes_without_sleeping() async {
        // Given
        let sleeper = ControlledSleeper()
        let sut = POSLockScreenIntro(sleep: sleeper.sleep)
        defer {
            sut.cancel()
            sleeper.finish()
        }

        // When
        await sut.run(shouldAnimate: false)

        // Then
        #expect(sut.phase == .finished)
        #expect(sleeper.durations.isEmpty)
    }

    @Test func test_run_when_cancelled_as_sleep_returns_then_does_not_advance_to_another_sleep() async {
        // Given
        var sleepCount = 0
        var onWake: (@MainActor () -> Void)?
        let sut = POSLockScreenIntro(sleep: { _ in
            sleepCount += 1
            onWake?()
        })
        onWake = { sut.cancel() }
        defer { onWake = nil }

        // When
        await sut.run(shouldAnimate: true)

        // Then
        #expect(sut.phase == .finished)
        #expect(sleepCount == 1)
    }

    @Test func test_run_when_sequence_has_finished_then_does_not_restart() async throws {
        // Given
        let sleeper = ControlledSleeper()
        let sut = POSLockScreenIntro(sleep: sleeper.sleep)
        defer {
            sut.cancel()
            sleeper.finish()
        }
        var sleeps = sleeper.calls.makeAsyncIterator()
        let caller = Task { await sut.run(shouldAnimate: true) }
        for duration: Duration in [.milliseconds(80), .seconds(0.2), .seconds(0.28)] {
            try await expectSleep(duration, from: &sleeps)
            sleeper.resumeNext()
        }
        await caller.value

        // When
        await sut.run(shouldAnimate: true)

        // Then
        #expect(sut.phase == .finished)
        #expect(sleeper.durations.count == 3)
    }
}

private extension POSLockScreenIntroTests {
    func expectSleep(_ duration: Duration, from iterator: inout AsyncStream<Duration>.Iterator) async throws {
        let next = await iterator.next()
        let actual = try #require(next)
        try #require(actual == duration)
    }

    @MainActor
    final class ControlledSleeper {
        let calls: AsyncStream<Duration>
        private(set) var durations: [Duration] = []
        private let callContinuation: AsyncStream<Duration>.Continuation
        private var pending: [CheckedContinuation<Void, Never>] = []
        private var isFinished = false

        init() {
            let stream = AsyncStream<Duration>.makeStream()
            calls = stream.stream
            callContinuation = stream.continuation
        }

        func sleep(_ duration: Duration) async throws {
            guard !isFinished else { throw CancellationError() }
            await withCheckedContinuation { continuation in
                pending.append(continuation)
                durations.append(duration)
                // Store the gate before signalling readiness; both operations run on the main actor.
                callContinuation.yield(duration)
            }
            try Task.checkCancellation()
        }

        func resumeNext() {
            guard !pending.isEmpty else {
                Issue.record("No sleep is pending")
                return
            }
            pending.removeFirst().resume()
        }

        func finish() {
            isFinished = true
            let continuations = pending
            pending.removeAll()
            continuations.forEach { $0.resume() }
            callContinuation.finish()
        }
    }
}
