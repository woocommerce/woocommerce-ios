import Foundation

//From : https://github.com/webadnan/swift-debouncer

/// This class de-bounces the execution of a provided callback.
/// It also offers a mechanism to immediately trigger the scheduled call if necessary.
///
/// Only used by the legacy `LoginSiteAddressViewController`; expected to go with it under AINFRA-601.
///
@MainActor
public final class Debouncer {
    // Read from the nonisolated deinit; every other access is main-actor isolated.
    nonisolated(unsafe) private var callback: (() -> Void)?
    private let delay: Double
    nonisolated(unsafe) private var timer: Timer?

    // MARK: - Init & deinit

    public init(delay: Double, callback: (() -> Void)? = nil) {
        self.delay = delay
        self.callback = callback
    }

    deinit {
        if let timer, timer.isValid, timer.fireDate >= Date() {
            timer.invalidate()
            callback?()
        }
    }

    // MARK: - Debounce Request

    public func cancel() {
        timer?.invalidate()
        timer = nil
    }

    public func call(immediate: Bool = false, callback: (() -> Void)? = nil) {
        timer?.invalidate()

        if let newCallback = callback {
            self.callback = newCallback
        }

        if immediate {
            immediateCallback()
        } else {
            scheduleCallback()
        }
    }

    // MARK: - Callback interaction

    private func immediateCallback() {
        timer = nil
        callback?()
    }

    private func scheduleCallback() {
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            // Scheduled from the main run loop, so the timer fires on the main thread.
            MainActor.assumeIsolated {
                self?.callback?()
            }
        }
    }
}
