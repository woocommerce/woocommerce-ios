import SwiftUI
import UIKit

/// UIKit installs the cover synchronously before the system captures the inactive app.
struct POSLockPrivacyCover: UIViewRepresentable {
    let session: POSAccessSession

    func makeUIView(context: Context) -> PrivacyView {
        PrivacyView(session: session)
    }

    func updateUIView(_ view: PrivacyView, context: Context) {
        view.updateCover()
    }

    static func dismantleUIView(_ view: PrivacyView, coordinator: ()) {
        view.removeCover()
    }

    final class PrivacyView: UIView {
        private let session: POSAccessSession
        private let cover = UIView()

        init(session: POSAccessSession) {
            self.session = session
            super.init(frame: .zero)
            isUserInteractionEnabled = false
            cover.backgroundColor = UIColor(Color.posSurfaceContainerLow)
            cover.accessibilityIdentifier = "pos-lock-privacy-cover"
            NotificationCenter.default.addObserver(self, selector: #selector(willResignActive),
                                                   name: UIApplication.willResignActiveNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive),
                                                   name: UIApplication.didBecomeActiveNotification, object: nil)
        }

        required init?(coder: NSCoder) { nil }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            updateCover()
        }

        func updateCover() {
            if session.isLocked, window?.windowScene?.activationState != .foregroundActive {
                showCover()
            } else {
                removeCover()
            }
        }

        func removeCover() {
            cover.removeFromSuperview()
        }

        @objc private func willResignActive() {
            if session.isLocked { showCover() }
        }

        @objc private func didBecomeActive() {
            removeCover()
        }

        private func showCover() {
            guard let window else { return }
            cover.frame = window.bounds
            cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            window.addSubview(cover)
        }
    }
}
