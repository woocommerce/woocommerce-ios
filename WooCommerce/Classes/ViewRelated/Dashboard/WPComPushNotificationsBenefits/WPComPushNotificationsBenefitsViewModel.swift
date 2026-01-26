import Foundation
import UIKit
import protocol WooFoundation.Analytics

final class WPComPushNotificationsBenefitsViewModel {
    // MARK: - Callbacks
    private let onDismiss: () -> Void

    // MARK: - Dependencies
    private let analytics: Analytics

    // MARK: - Init
    init(onDismiss: @escaping () -> Void,
         analytics: Analytics = ServiceLocator.analytics) {
        self.onDismiss = onDismiss
        self.analytics = analytics
    }

    // MARK: - Actions
    func onAppear() {
        // TODO: Track modal shown event
    }

    func continueTapped() {
        // TODO: Track continue tapped event
    }

    func notNowTapped() {
        // TODO: Track not now tapped event
        onDismiss()
    }

    func whatIsWPComTapped() {
        // TODO: Track link tapped event
        UIApplication.shared.open(WooConstants.URLs.whatIsWPCom.asURL())
    }
}
