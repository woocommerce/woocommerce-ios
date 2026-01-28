import Foundation
import protocol WooFoundation.Analytics

final class WPComPushNotificationsBenefitsViewModel {

    private let analytics: Analytics

    init(analytics: Analytics = ServiceLocator.analytics) {
        self.analytics = analytics
    }

    func onAppear() {
        // TODO: Track modal shown event
    }

    func continueTapped() {
        // TODO: Track continue tapped event
    }

    func notNowTapped() {
        // TODO: Track not now tapped event
    }

    func whatIsWPComTapped() {
        // TODO: Track link tapped event
    }
}
