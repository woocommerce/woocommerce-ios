import Foundation
import UIKit
import UserNotifications
import WordPressUI


/// NoticePresenter: Coordinates Notice rendering, in both, FG and BG execution modes.
///
class NoticePresenter {

    /// UIKit Feedback Gen!
    ///
    private let generator = UINotificationFeedbackGenerator()

    /// Notices Queue.
    ///
    private var notices = [Notice]()

    /// Notice currently onScreen
    ///
    private var noticeOnScreen: Notice?

    /// TODO: Background Notifications are disabled, for now.
    ///
    private let supportsBackgroundNotifications = false

    /// UIViewController to be used as Notice(s) Presenter
    ///
    weak var presentingViewController: UIViewController?


    /// Enqueues the specified Notice for display.
    ///
    func enqueue(notice: Notice) {
        notices.append(notice)
        presentNextNoticeIfPossible()
    }
}


// MARK: - Private Methods
//
private extension NoticePresenter {

    func presentNextNoticeIfPossible() {
        guard noticeOnScreen == nil, let next = notices.popFirst() else {
            return
        }

        present(next)
        noticeOnScreen = next
    }

    func present(_ notice: Notice) {
        if supportsBackgroundNotifications && UIApplication.shared.applicationState == .background {
            presentNoticeInBackground(notice)
        } else {
            presentNoticeInForeground(notice)
        }
    }

    func presentNoticeInBackground(_ notice: Notice) {
        guard let notificationInfo = notice.notificationInfo else {
            return
        }

        let content = UNMutableNotificationContent(notice: notice)
        let request = UNNotificationRequest(identifier: notificationInfo.identifier, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                self.dismiss()
            }
        }
    }

    func presentNoticeInForeground(_ notice: Notice) {
        guard let view = presentingViewController?.view else {
                return
        }

        generator.prepare()

        let noticeView = NoticeView(notice: notice)
        noticeView.translatesAutoresizingMaskIntoConstraints = false

        let noticeContainerView = NoticeContainerView(noticeView: noticeView)
        addNoticeContainerToPresentingViewController(noticeContainerView)

        let bottomConstraint = makeBottomConstraintForNoticeContainer(noticeContainerView)

        NSLayoutConstraint.activate([
            noticeContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noticeContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomConstraint
        ])

        let fromState = {
            noticeView.alpha = UIKitConstants.alphaZero
            bottomConstraint.constant = self.offscreenBottomOffset

            view.layoutIfNeeded()
        }

        let toState = {
            noticeView.alpha = UIKitConstants.alphaFull
            bottomConstraint.constant = 0

            view.layoutIfNeeded()
        }

        let dismiss = {
            guard noticeContainerView.superview != nil else {
                return
            }

            self.animatePresentation(fromState: {}, toState: fromState, completion: {
                noticeContainerView.removeFromSuperview()
                self.dismiss()
            })
        }

        noticeView.dismissHandler = dismiss

        if let feedbackType = notice.feedbackType {
            generator.notificationOccurred(feedbackType)
        }

        animatePresentation(fromState: fromState, toState: toState, completion: {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Animations.dismissDelay, execute: dismiss)
        })
    }

    func dismiss() {
        noticeOnScreen = nil
        presentNextNoticeIfPossible()
    }

    func addNoticeContainerToPresentingViewController(_ noticeContainer: UIView) {
        if let tabBarController = presentingViewController as? UITabBarController {
            tabBarController.view.insertSubview(noticeContainer, belowSubview: tabBarController.tabBar)
        } else {
            presentingViewController?.view.addSubview(noticeContainer)
        }
    }

    func makeBottomConstraintForNoticeContainer(_ container: UIView) -> NSLayoutConstraint {
        guard let presentingViewController = presentingViewController else {
            fatalError("NoticePresenter requires a presentingViewController!")
        }

        if let tabBarController = presentingViewController as? UITabBarController {
            return container.bottomAnchor.constraint(equalTo: tabBarController.tabBar.topAnchor)
        }

        return container.bottomAnchor.constraint(equalTo: presentingViewController.view.bottomAnchor)
    }

    var offscreenBottomOffset: CGFloat {
        if let tabBarController = presentingViewController as? UITabBarController {
            return tabBarController.tabBar.bounds.height
        }

        return 0
    }

    func animatePresentation(fromState: () -> Void, toState: @escaping () -> Void, completion: @escaping () -> Void) {
        fromState()

        UIView.animate(withDuration: Animations.appearanceDuration,
                       delay: 0,
                       usingSpringWithDamping: Animations.appearanceSpringDamping,
                       initialSpringVelocity: Animations.appearanceSpringVelocity,
                       options: [],
                       animations: toState,
                       completion: { _ in
                        completion()
        })
    }

    private enum Animations {
        static let appearanceDuration: TimeInterval = 1.0
        static let appearanceSpringDamping: CGFloat = 0.7
        static let appearanceSpringVelocity: CGFloat = 0.0
        static let dismissDelay: TimeInterval = 5.0
    }
}


// MARK: - NoticeContainerView: Small wrapper view that ensures a notice remains centered and at a maximum width when
//         displayed in a regular size class.
//
private class NoticeContainerView: UIView {

    let containerMargin: CGFloat = 16.0

    let noticeView: NoticeView

    init(noticeView: NoticeView) {
        self.noticeView = noticeView

        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false

        layoutMargins = UIEdgeInsets(top: containerMargin, left: containerMargin, bottom: containerMargin, right: containerMargin)

        // Padding views on either side, of equal width to ensure centering
        let leftPaddingView = UIView()
        let rightPaddingView = UIView()
        rightPaddingView.translatesAutoresizingMaskIntoConstraints = false
        leftPaddingView.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView(arrangedSubviews: [leftPaddingView, noticeView, rightPaddingView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 0

        let paddingWidthConstraint = leftPaddingView.widthAnchor.constraint(equalToConstant: 0)
        paddingWidthConstraint.priority = .defaultLow

        addSubview(stackView)

        NSLayoutConstraint.activate([
            paddingWidthConstraint,
            leftPaddingView.widthAnchor.constraint(equalTo: rightPaddingView.widthAnchor),
            stackView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor)
            ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var noticeWidthConstraint: NSLayoutConstraint = {
        // At regular width, the notice shouldn't be any wider than 1/2 the app's width
        return noticeView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5)
    }()

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        let isRegularWidth = traitCollection.containsTraits(in: UITraitCollection(horizontalSizeClass: .regular))
        noticeWidthConstraint.isActive = isRegularWidth

        layoutIfNeeded()
    }
}


// MARK: - UNMutableNotificationContent Notice Methods
//
private extension UNMutableNotificationContent {
    convenience init(notice: Notice) {
        self.init()

        title = notice.notificationInfo?.title ?? notice.title

        if let body = notice.notificationInfo?.body {
            self.body = body
        } else if let message = notice.message {
            subtitle = message
        }

        if let categoryIdentifier = notice.notificationInfo?.categoryIdentifier {
            self.categoryIdentifier = categoryIdentifier
        }

        if let userInfo = notice.notificationInfo?.userInfo {
            self.userInfo = userInfo
        }

        sound = .default()
    }
}
