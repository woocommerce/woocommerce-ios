import Foundation
import UIKit
import SwiftUI

/// This struct encapsulates the content to displayed in a Permanent Notice
///
struct PermanentNotice {
    let message: String
    let callToActionTitle: String
    let callToActionHandler: () -> Void
}

/// Presents a banner permanently, that is, will remain until it is called to dismiss, unlike `DefaultNoticePresenter`, which dismiss the notice after a delay.
/// The design also differs with the latter to represent a more permanent air.
///
final class PermanentNoticePresenter {
    private var hostingController: UIHostingController<PermanentNoticeView>?

    /// Presents the given notice into the passed view controller with an animation
    ///
    func presentNotice(notice: PermanentNotice, from viewController: UIViewController) {
        let permanentNoticeView = PermanentNoticeView(notice: notice)
        let newHostingController = ConstraintsUpdatingHostingController(rootView: permanentNoticeView)

        guard let hostingView = newHostingController.view else {
            return
        }

        viewController.addChild(newHostingController)
        viewController.view.addSubview(hostingView)

        setupConstraints(in: viewController, hostingView: hostingView)
        animatePresentation(of: newHostingController, in: viewController)

        self.hostingController = newHostingController
    }

    /// Dismiss the permanent notice presented by calling `presentNotice`. If there is no one presented this method does nothing.
    ///
    func dismiss() {
        animateDismiss()
    }
}

private extension PermanentNoticePresenter {
    func setupConstraints(in viewController: UIViewController, hostingView: UIView) {
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            viewController.view.leadingAnchor.constraint(equalTo: hostingView.leadingAnchor, constant: 0),
            viewController.view.trailingAnchor.constraint(equalTo: hostingView.trailingAnchor, constant: 0),
            viewController.view.bottomAnchor.constraint(equalTo: hostingView.bottomAnchor, constant: 0),
            ])
    }

    func animatePresentation(of hostingController: UIViewController, in viewController: UIViewController) {
        guard let hostingView = hostingController.view else {
            return
        }

        hostingView.alpha = 0

        UIView.animate(withDuration: Animations.appearanceDuration,
                       delay: 0,
                       options: .transitionFlipFromLeft, animations: {
            hostingView.alpha = 1
            }) { _ in
                hostingController.didMove(toParent: viewController)
            }
    }

    func animateDismiss() {
        guard let hostingController = hostingController else {
            return
        }

        UIView.animate(withDuration: Animations.appearanceDuration,
                       delay: 0,
                       options: .transitionFlipFromLeft, animations: {
            hostingController.view.alpha = 0
            }) { _ in
                hostingController.willMove(toParent: nil)
                hostingController.view.removeFromSuperview()
            }
    }
}

private extension PermanentNoticePresenter {
    private enum Animations {
        static let appearanceDuration: TimeInterval = 0.5
    }
}
