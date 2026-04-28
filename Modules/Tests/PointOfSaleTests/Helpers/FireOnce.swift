import Foundation

/// Awaits a single mock-callback fire and ignores any duplicates.
///
/// Pass `fire` to whatever hook the test installs; the first call resumes the
/// underlying continuation, subsequent calls are no-ops. The dedupe is
/// thread-safe so the hook can be invoked from any actor.
///
/// ```swift
/// await fireOnce { fire in
///     coordinator.onPerformIncrementalSyncCalled = { fire() }
///     Task { @MainActor in await sut.checkOut() }
/// }
/// ```
@MainActor
func fireOnce(_ body: (_ fire: @escaping @Sendable () -> Void) -> Void) async {
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
        let lock = NSLock()
        nonisolated(unsafe) var fired = false
        body {
            lock.lock()
            defer { lock.unlock() }
            guard !fired else { return }
            fired = true
            continuation.resume()
        }
    }
}
