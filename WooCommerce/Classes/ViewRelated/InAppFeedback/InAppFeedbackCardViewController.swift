
import UIKit

/// Displays a small view asking the user to provide a feedback for the app.
///
final class InAppFeedbackCardViewController: UIViewController {

    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var didNotLikeButton: UIButton!
    @IBOutlet private var likeButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTitleLabel()
        configureDidNotLikeButton()
        configureLikeButton()

        view.backgroundColor = .listForeground
    }
}

// MARK: - Provisioning

private extension InAppFeedbackCardViewController {
    func configureTitleLabel() {
        titleLabel.applyBodyStyle()
        titleLabel.numberOfLines = 0
        titleLabel.text = Localization.enjoyingTheWooCommerceApp
    }

    func configureDidNotLikeButton() {
        didNotLikeButton.applySecondaryButtonStyle()
        didNotLikeButton.setTitle(Localization.couldBeBetter, for: .normal)
    }

    func configureLikeButton() {
        likeButton.applyPrimaryButtonStyle()
        likeButton.setTitle(Localization.iLikeIt, for: .normal)
    }
}

// MARK: - Constants

private extension InAppFeedbackCardViewController {
    enum Localization {
        static let enjoyingTheWooCommerceApp = NSLocalizedString("Enjoying the WooCommerce app?",
                                                                 comment: "The title used when asking the user for feedback for the app.")
        static let couldBeBetter = NSLocalizedString("Could Be Better",
                                                     comment: "The title of the button for giving a negative feedback for the app.")
        static let iLikeIt = NSLocalizedString("I Like It",
                                               comment: "The title of the button for giving a positive feedback for the app.")
    }
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
    }

    static var previews: some View {
        Group {
            makeStack()
                .previewLayout(.fixed(width: 320, height: 128))
                .previewDisplayName("Light")

            makeStack()
                .previewLayout(.fixed(width: 375, height: 128))
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Dark")

            makeStack()
                .previewLayout(.fixed(width: 414, height: 528))
                .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
                .previewDisplayName("Large Font")

            makeStack()
                .previewLayout(.fixed(width: 896, height: 128))
                .environment(\.colorScheme, .dark)
                .previewDisplayName("Large Width - Dark")
        }
    }
}

#endif
