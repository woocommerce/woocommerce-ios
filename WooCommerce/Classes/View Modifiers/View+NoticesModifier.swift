import SwiftUI
import UIKit

/// View Modifier that shows a notice in front of a view.
///
struct NoticeModifier: ViewModifier {

    /// Notice object to render
    ///
    let notice: Notice

    func body(content: Content) -> some View {
        content.overlay(
            // Geometry reader to provide the correct view width.
            GeometryReader { geometry in
                // VStack with spacer to push content to the bottom
                VStack {
                    Spacer()

                    // NoticeView wrapper
                    NoticeAlert(notice: notice, width: geometry.size.width)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        )
    }
}

// MARK: Custom Views

/// `SwiftUI` representable type for `NoticeView`.
///
private struct NoticeAlert: UIViewRepresentable {

    /// Notice object render
    ///
    let notice: Notice

    /// Desired width of the view.
    ///
    let width: CGFloat

    func makeUIView(context: Context) -> NoticeWrapper {
        let noticeView = NoticeView(notice: notice)
        let wrapperView = NoticeWrapper(noticeView: noticeView)
        wrapperView.translatesAutoresizingMaskIntoConstraints = false
        return wrapperView
    }

    func updateUIView(_ uiView: NoticeWrapper, context: Context) {
        uiView.width = width
    }
}


private extension NoticeAlert {
    /// Wrapper type to force the underlying `NoticeView` to fixed width
    ///
    class NoticeWrapper: UIView {
        /// Underlying notice view
        ///
        let noticeView: NoticeView

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
        let defaultInsets = UIEdgeInsets(top: 16, left: 16, bottom: 28, right: 16)

        init(noticeView: NoticeView) {
            self.noticeView = noticeView
            super.init(frame: .zero)

            // Add notice view to edges
            noticeView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(noticeView)

            layoutMargins = defaultInsets
            pinSubviewToAllEdgeMargins(noticeView)

            noticeViewWidthConstraint = widthAnchor.constraint(equalToConstant: width)
            noticeViewWidthConstraint.isActive = true
        }

        /// Returns the preferred size of the view using the fixed width.
        ///
        override var intrinsicContentSize: CGSize {
            let targetSize =  CGSize(width: width - defaultInsets.left - defaultInsets.right, height: 0)
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
    func notice(_ notice: Notice) -> some View {
        self.modifier(NoticeModifier(notice: notice))
    }
}

// MARK: Preview

struct NoticeModifier_Previews: PreviewProvider {
    static var previews: some View {
        Rectangle().foregroundColor(.white)
            .notice(
                .init(title: "API Error",
                      subtitle: "Restricted Access",
                      message: "Your photos could not be downloaded, please ask for the correct permissions!",
                      feedbackType: .error,
                      notificationInfo: nil,
                      actionTitle: "Retry",
                      actionHandler: {
                          print("Retry")
                      })
            )
            .environment(\.colorScheme, .light)
            .previewDisplayName("Light Content")
    }
}
