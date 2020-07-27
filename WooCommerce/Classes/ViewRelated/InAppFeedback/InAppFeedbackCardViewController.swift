
import UIKit

/// Displays a small view asking the user to provide a feedback for the app.
///
final class InAppFeedbackCardViewController: UIViewController {

}

// MARK: - Previews

#if canImport(SwiftUI) && DEBUG

import SwiftUI

private struct InAppFeedbackCardViewControllerRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let viewController = InAppFeedbackCardViewController()
        return viewController.view
    }

    func updateUIView(_ view: UIView, context: Context) {
        // noop
    }
}

@available(iOS 13.0, *)
struct InAppFeedbackCardViewController_Previews: PreviewProvider {

    private static func makeStack() -> some View {
        VStack {
            InAppFeedbackCardViewControllerRepresentable()
        }
        .background(Color(UIColor.listBackground))
    }

    static var previews: some View {
        Group {
            makeStack()
                .previewLayout(.fixed(width: 375, height: 128))
                .previewDisplayName("Light")

            makeStack()
                .previewLayout(.fixed(width: 375, height: 128))
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Dark")

            makeStack()
                .previewLayout(.fixed(width: 375, height: 128))
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
                .previewDisplayName("Large Font")
        }
    }
}

#endif
