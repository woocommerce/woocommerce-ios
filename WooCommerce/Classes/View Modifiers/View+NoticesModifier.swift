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
            .overlay(
                buildNoticeStack()
                    .padding()
                    .animation(.easeInOut, value: notice)
            )
    }

    private enum Constants {
        static let titleFont: Font = Font(UIFont.boldSystemFont(ofSize: 14.0))
        static let titleColor: Color = Color(.text)
        static let subtitleFont: Font = Font(UIFont.boldSystemFont(ofSize: 14.0))
        static let subtitleColor: Color = Color(.text)
        static let messageFont: Font = Font(UIFont.systemFont(ofSize: 14.0))
        static let messageColor: Color = Color(.text)
        static let actionButtonFont: Font = Font(UIFont.systemFont(ofSize: 14.0))
        static let actionButtonColor: Color = Color(.primaryButtonBackground)
        static let actionButtonBackgroundColor: Color = Color(UIColor.systemColor(.secondarySystemGroupedBackground))
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
                    HStack(spacing: 0.0) {
                        VStack {
                            HStack {
                                Text(notice.title)
                                    .lineLimit(notice.message.isNilOrEmpty ? 0 : 2)
                                Spacer()
                            }
                            .font(Constants.titleFont)
                            .foregroundColor(Constants.titleColor)
                            if let subtitle = notice.subtitle {
                                HStack {
                                    Text(subtitle)
                                    Spacer()
                                }
                                .font(Constants.subtitleFont)
                                .foregroundColor(Constants.subtitleColor)
                            }
                            if let message = notice.message {
                                HStack {
                                    Text(message)
                                    Spacer()
                                }
                                .font(Constants.messageFont)
                                .foregroundColor(Constants.messageColor)
                            }
                        }
                        .frame(maxHeight: .infinity)
                        .padding()
                        if let actionTitle = notice.actionTitle {
                            Button(action: {
                                notice.actionHandler?()
                                performClearNoticeTask()
                            }, label: {
                                VStack {
                                    Text(actionTitle)
                                        .padding()
                                        .font(Constants.actionButtonFont)
                                        .foregroundColor(Constants.actionButtonColor)
                                }
                            })
                            .frame(maxHeight: .infinity)
                            .background(Constants.actionButtonBackgroundColor)
                        }
                    }
                    .background(.thickMaterial)
                    .frame(width: preferredSizeClassWidth(geometry))
                    .fixedSize(horizontal: false, vertical: true)
                    .cornerRadius(13.0)
                    .onTapGesture {
                        performClearNoticeTask()
                    }
                    .simultaneousGesture(
                        DragGesture().onChanged({ _ in
                            performClearNoticeTask()
                        })
                    )
                    .onChange(of: notice) { _ in
                        provideHapticFeedbackIfNecessary(notice.feedbackType)
                        dispatchClearNoticeTask()
                    }
                    .onAppear {
                        provideHapticFeedbackIfNecessary(notice.feedbackType)
                        dispatchClearNoticeTask()
                    }
                    .shadow(color: .black.opacity(0.2), radius: 8.0, x: 0.0, y: 2.0)
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
        setClearNoticeTask()
        DispatchQueue.main.asyncAfter(deadline: .now() + onScreenNoticeTime, execute: clearNoticeTask)
    }

    /// Synchronously performs the clear notice task and cancels it to prevent any future execution.
    ///
    private func performClearNoticeTask() {
        setClearNoticeTask()
        clearNoticeTask.perform()
        clearNoticeTask.cancel()
    }

    /// Sets the clear notice task.
    ///
    private func setClearNoticeTask() {
        clearNoticeTask = .init {
            $notice.wrappedValue = nil
        }
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
