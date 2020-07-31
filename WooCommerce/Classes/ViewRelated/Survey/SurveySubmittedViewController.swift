import UIKit

/// Shows a completion screen once a survey has been submitted
///
final class SurveySubmittedViewController: UIViewController {

    /// Thank you label at the top
    ///
    @IBOutlet private weak var thankYouLabel: UILabel!

    /// Info label at the middle
    ///
    @IBOutlet private weak var infoLabel: UILabel!

    /// Stackview to align the contact us button horizontally
    ///
    @IBOutlet private weak var linkButtonStackView: UIStackView!

    /// Need help indicator label
    ///
    @IBOutlet private weak var needHelpLabel: UILabel!

    /// Link button to contact support
    ///
    @IBOutlet private weak var contactUsButton: UIButton!

    /// Button to go back to the store
    ///
    @IBOutlet private weak var backToStoreButton: UIButton!

    /// CrowdSignal attribution label
    ///
    @IBOutlet private weak var poweredLabel: UILabel!

    /// Used to present the Contact Support dialog
    private let zendeskManager: ZendeskManagerProtocol

    init(zendeskManager: ZendeskManagerProtocol = ZendeskManager.shared) {
        self.zendeskManager = zendeskManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported.")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addCloseNavigationBarButton()
        applyStyleToComponents()
        applyLocalizedTextsToComponents()
        configureStackViewsAxis()
    }

    @IBAction private func contactUsButtonTapped(_ sender: Any) {
        zendeskManager.showNewRequestIfPossible(from: self, with: nil)
    }

    @IBAction private func backToStoreButtonPressed(_ sender: Any) {
        // Assumes it's in a presentation context. To be addressed in a following PR.
        dismiss(animated: true, completion: nil)
    }

}

// MARK: View Configuration
//
private extension SurveySubmittedViewController {

    /// Apply UI styles
    ///
    func applyStyleToComponents() {
        thankYouLabel.applyHeadlineStyle()
        infoLabel.applyCalloutStyle()
        needHelpLabel.applyCalloutStyle()
        backToStoreButton.applyPrimaryButtonStyle()
        poweredLabel.applyCaption1Style()

        contactUsButton.applyLinkButtonStyle()
        contactUsButton.titleLabel?.applyCalloutStyle()
        contactUsButton.contentEdgeInsets = .zero
    }

    /// Apply the correspondent localized texts to each component
    ///
    func applyLocalizedTextsToComponents() {
        title = Localization.title
        thankYouLabel.text = Localization.thanks
        infoLabel.text = Localization.info
        needHelpLabel.text = Localization.needHelp
        poweredLabel.text = Localization.surveyAttributtion

        contactUsButton.setTitle(Localization.contactUs, for: .normal)
        backToStoreButton.setTitle(Localization.backToStore, for: .normal)
    }

    /// Changes the axis of the stack views that  need speacial treatment on larger size categories
    ///
    func configureStackViewsAxis() {
        linkButtonStackView.axis = traitCollection.preferredContentSizeCategory > .extraExtraExtraLarge ? .vertical : .horizontal
    }
}

// MARK: Accessibility handling
//
extension SurveySubmittedViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        configureStackViewsAxis()
    }
}

// MARK: Constants
//
private extension SurveySubmittedViewController {
    enum Localization {
        static let title = NSLocalizedString("Feedback Sent!", comment: "Title in the navigation bar when the survey is completed")
        static let thanks = NSLocalizedString("Thank you for sharing your\nthoughts with us", comment: "Text thanking the user when the survey is completed")
        static let info = NSLocalizedString("Keep in mind that this is not a\nsupport ticket and we won’t be able\nto address individual feedback",
                                            comment: "Information text when the survey is completed")
        static let needHelp = NSLocalizedString("Need some help?", comment: "Text preceding the Contact Us button in the survey completed screen")
        static let contactUs = NSLocalizedString("Contact us here", comment: "Title of a button to contact support in the survey complete screen")
        static let backToStore = NSLocalizedString("Back to store", comment: "Title of a button to dismiss the survey complete screen")
        static let surveyAttributtion = NSLocalizedString("Powered by Automattic", comment: "Info text saying that crowdsignal in an Automattic product")
    }
}
