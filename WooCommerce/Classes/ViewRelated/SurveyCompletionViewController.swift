import UIKit

final class SurveyCompletionViewController: UIViewController {
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var contactUsButton: UIButton!
    @IBOutlet private weak var backToStoreButton: UIButton!

    private let onContactUsAction: () -> Void
    private let onBackToStoreAction: () -> Void

    init(onContactUsAction: @escaping () -> Void, onBackToStoreAction: @escaping () -> Void) {
        self.onContactUsAction = onContactUsAction
        self.onBackToStoreAction = onBackToStoreAction
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO-jc: localize
        headerLabel.text = "Thank you for sharing your thoughts with us"
        headerLabel.applyHeadlineStyle()

        // TODO-jc: localize
        backToStoreButton.applyLinkButtonStyle()
        contactUsButton.setTitle("Contact us here", for: .normal)
        contactUsButton.addTarget(self, action: #selector(contactUsButtonTapped), for: .touchUpInside)

        // TODO-jc: localize
        backToStoreButton.applyPrimaryButtonStyle()
        backToStoreButton.setTitle("Back to Store", for: .normal)
        backToStoreButton.addTarget(self, action: #selector(backToStoreButtonTapped), for: .touchUpInside)
    }
}

private extension SurveyCompletionViewController {
    @objc func contactUsButtonTapped() {
        onContactUsAction()
    }

    @objc func backToStoreButtonTapped() {
        onBackToStoreAction()
    }
}
