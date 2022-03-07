import SwiftUI
import UIKit

/// View Modifier that shows a notice in front of a view.
///
/// NOTE: This currently does not support:
/// - Enqueuing multiple notices like `DefaultNoticePresenter` does.
/// - Presenting foreground system notifications.
///
struct NoticeModifier: ViewModifier {
    /// Notice object to render.
    ///
    @Binding var notice: Notice?

    /// Whether the notice should be auto-dismissed.
    ///
    let autoDismiss: Bool

    /// Cancelable task that clears a notice.
    ///
    @State private var clearNoticeTask = DispatchWorkItem(block: {})

    /// Time the notice will remain on screen, if it is auto-dismissed.
    ///
    private let onScreenNoticeTime = 5.0

    /// Feedback generator.
    ///
    private let feedbackGenerator = UINotificationFeedbackGenerator()

    /// Current horizontal size class.
    ///
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    func body(content: Content) -> some View {
        content
            .overlay(buildNoticeStack())
            .animation(.easeInOut, value: notice)
    }

    /// Builds a notice view at the bottom of the screen.
    ///
    @ViewBuilder private func buildNoticeStack() -> some View {
        if let notice = notice {
            // Geometry reader to provide the correct view width.
            GeometryReader { geometry in

                // VStack with spacer to push content to the bottom
                VStack {
                    Spacer()

                    // NoticeView wrapper
                    NoticeAlert(notice: notice, width: preferredSizeClassWidth(geometry))
                        .onDismiss {
                            performClearNoticeTask()
                        }
                        .onChange(of: notice) { _ in
                            provideHapticFeedbackIfNecessary(notice.feedbackType)
                            dispatchClearNoticeTask()
                        }
                        .onAppear {
                            provideHapticFeedbackIfNecessary(notice.feedbackType)
                            dispatchClearNoticeTask()
                        }
                        .fixedSize()
                }
                .frame(width: geometry.size.width) // Force a full container width so the notice is always centered.
            }
        }
    }

    /// Cancels any ongoing clear notice task and dispatches it again, if the notice should be auto-dismissed.
    ///
    private func dispatchClearNoticeTask() {
        guard autoDismiss else { return }
        clearNoticeTask.cancel()
        clearNoticeTask = .init {
            $notice.wrappedValue = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + onScreenNoticeTime, execute: clearNoticeTask)
    }

    /// Synchronously performs the clear notice task and cancels it to prevent any future execution.
    ///
    private func performClearNoticeTask() {
        clearNoticeTask.perform()
        clearNoticeTask.cancel()
    }

    /// Sends haptic feedback if required.
    ///
    private func provideHapticFeedbackIfNecessary(_ feedbackType: UINotificationFeedbackGenerator.FeedbackType?) {
        if let feedbackType = feedbackType {
            feedbackGenerator.notificationOccurred(feedbackType)
        }
    }

    /// Returns a scaled width for a regular horizontal size class.
    ///
    private func preferredSizeClassWidth(_ geometry: GeometryProxy) -> CGFloat {
        let multiplier = horizontalSizeClass == .regular ? 0.5 : 1.0
        return geometry.size.width * multiplier
    }
}

// MARK: Custom Views

/// `SwiftUI` representable type for `NoticeView`.
///
private struct NoticeAlert: UIViewRepresentable {

    /// Notice object to render.
    ///
    let notice: Notice

    /// Desired width of the view.
    ///
    let width: CGFloat

    /// Action to be invoked when the view is tapped.
    ///
    var onDismiss: (() -> Void)?

    func makeUIView(context: Context) -> NoticeWrapper {
        let noticeView = NoticeView(notice: notice)
        let wrapperView = NoticeWrapper(noticeView: noticeView)
        wrapperView.translatesAutoresizingMaskIntoConstraints = false
        return wrapperView
    }

    func updateUIView(_ uiView: NoticeWrapper, context: Context) {
        uiView.noticeView = NoticeView(notice: notice)
        uiView.noticeView.dismissHandler = onDismiss
        uiView.width = width
    }

    /// Updates the notice dismiss closure.
    ///
    func onDismiss(_ onDismiss: @escaping (() -> Void)) -> Self {
        var copy = self
        copy.onDismiss = onDismiss
        return copy
    }
}


private extension NoticeAlert {
    /// Wrapper type to force the underlying `NoticeView` to have a fixed width.
    ///
    class NoticeWrapper: UIView {
        /// Underlying notice view
        ///
        var noticeView: NoticeView {
            didSet {
                oldValue.removeFromSuperview()
                setUpNoticeLayout()
            }
        }

        /// Fixed width constraint.
        ///
        var width: CGFloat = 0 {
            didSet {
                noticeViewWidthConstraint.constant = width
            }
        }

        /// Width constraint for the notice view.
        ///
        private var noticeViewWidthConstraint = NSLayoutConstraint()

        /// Notice view padding.
        ///
        let defaultInsets = UIEdgeInsets(top: 16, left: 16, bottom: 32, right: 16)

        init(noticeView: NoticeView) {
            self.noticeView = noticeView
            super.init(frame: .zero)

            setUpNoticeLayout()
            createWidthConstraint()
        }

        /// Set ups the notice layout.
        ///
        private func setUpNoticeLayout() {
            // Add notice view to edges
            noticeView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(noticeView)

            layoutMargins = defaultInsets
            pinSubviewToAllEdgeMargins(noticeView)
        }

        /// Forces the wrapper view to have a fixed width.
        ///
        private func createWidthConstraint() {
            noticeViewWidthConstraint = widthAnchor.constraint(equalToConstant: width)
            noticeViewWidthConstraint.isActive = true
        }

        /// Returns the preferred size of the view using the fixed width.
        ///
        override var intrinsicContentSize: CGSize {
            let targetSize = CGSize(width: width - defaultInsets.left - defaultInsets.right, height: 0)
            let noticeHeight = noticeView.systemLayoutSizeFitting(
                targetSize,
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .defaultLow
            ).height
            return CGSize(width: width, height: noticeHeight + defaultInsets.top + defaultInsets.bottom)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

// MARK: View Extension

extension View {
    /// Shows the provided notice in front of the view.
    ///
    /// - Parameters:
    ///   - notice: Notice to be displayed.
    ///   - autoDismiss: Whether the notice should be auto-dismissed.
    func notice(_ notice: Binding<Notice?>, autoDismiss: Bool = true) -> some View {
        modifier(NoticeModifier(notice: notice, autoDismiss: autoDismiss))
    }
}

extension UIHostingController {
    /// Enqueues a notice into the provided `noticePresenter` when the receiver is being removed.
    /// Uses `ServiceLocator.noticePresenter` if not presenter is provided.
    ///
    func enqueuePendingNotice(_ notice: Notice?, using noticePresenter: NoticePresenter = ServiceLocator.noticePresenter) {
        let isBeingRemoved: Bool = {
            isMovingFromParent ||               // when navigating out of a navigation stack
            isBeingDismissed ||                 // when being dismissed as modal
            parent?.isBeingDismissed ?? false   // when it's parent is being dismissed as modal (EG: inside a navigation controller)
        }()

        if let notice = notice, isBeingRemoved {
            noticePresenter.enqueue(notice: notice)
        }
    }
}

// MARK: Preview

struct NoticeModifier_Previews: PreviewProvider {
    static var previews: some View {
        Rectangle().foregroundColor(.white)
            .notice(.constant(
                .init(title: "API Error",
                      subtitle: "Restricted Access",
                      message: "Your photos could not be downloaded, please ask for the correct permissions!",
                      feedbackType: .error,
                      notificationInfo: nil,
                      actionTitle: "Retry",
                      actionHandler: {
                          print("Retry")
                      })
            ))
            .environment(\.colorScheme, .light)
            .previewDisplayName("Light Content")
    }
}
