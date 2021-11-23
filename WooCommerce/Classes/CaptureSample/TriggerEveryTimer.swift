/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A helper class that runs a timer and fires a closure at regular intervals.
*/

import Combine
import Foundation

/// This is a helper class that creates a `Timer` to repeatedly call a closure. This class also calls a
/// `Progress` closure periodically with the remaining time. It runs all closures on the main thread.
class TriggerEveryTimer {
    private let triggerEverySecs: Double
    private let updateEverySecs: Double
    private var lastTriggerTime: Date = Date()
    private var timerHandle: AnyCancellable? = nil
    private let onTrigger: (() -> Void)?
    private let onUpdate: ((Double) -> Void)?

    init(triggerEvery: Double, onTrigger: @escaping (() -> Void), updateEvery: Double,
         onUpdate: ((Double) -> Void)? = nil) {
        self.triggerEverySecs = triggerEvery
        self.updateEverySecs = updateEvery

        self.onTrigger = onTrigger
        self.onUpdate = onUpdate
    }

    var isRunning: Bool {
        return timerHandle != nil
    }

    func start() {
        lastTriggerTime = Date()
        timerHandle = Timer.publish(every: updateEverySecs, on: .main, in: .common)
            .autoconnect()
            .sink(receiveValue: { date in
                let timeToGoSecs = self.triggerEverySecs -
                    date.timeIntervalSince(self.lastTriggerTime)
                if timeToGoSecs <= 0 {
                    self.onTrigger?()
                    self.lastTriggerTime = date
                }
                self.onUpdate?(timeToGoSecs)
            })
    }

    func stop() {
        timerHandle?.cancel()
        timerHandle = nil
    }
}
