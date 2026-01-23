import UIKit

/// Outputs of the the `SurveySubmittedViewController`
///
protocol SurveySubmittedViewControllerOutputs: UIViewController {
    /// Closure invoked when tapping the contact us button
    ///
    var onContactUsAction: (() -> Void)? { get }

    /// Closure invoked when tapping the back to store button
    ///
    var onBackToStoreAction: (() -> Void)? { get }
}

/// Shows a completion screen once a survey has been submitted
///
final class SurveySubmittedViewController: UIViewController, SurveySubmittedViewControllerOutputs {

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

    /// Closure invoked when tapping the contact us button
    ///
    var onContactUsAction: (() -> Void)?

    /// Closure invoked when tapping the back to store button
    ///
    var onBackToStoreAction: (() -> Void)?

    init() {
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
        observeTraitChanges()
    }

    private func observeTraitChanges() {
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: Self, _) in
            self.configureStackViewsAxis()
        }
    }

    @IBAction private func contactUsButtonTapped(_ sender: Any) {
        onContactUsAction?()
    }

    @IBAction private func backToStoreButtonPressed(_ sender: Any) {
        onBackToStoreAction?()
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
        var contactUsConfiguration = UIButton.Configuration.plain()
        contactUsConfiguration.contentInsets = .init(.zero)
        contactUsButton.configuration = contactUsConfiguration
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

// MARK: Constants
//
private extension SurveySubmittedViewController {
    enum Localization {
        static let title = NSLocalizedString("Feedback Sent!", comment: "Title in the navigation bar when the survey is completed")
        static let thanks = NSLocalizedString("Thank you for sharing your thoughts with us", comment: "Text thanking the user when the survey is completed")
        static let info = NSLocalizedString("Keep in mind that this is not a support ticket and we won’t be able to address individual feedback",
                                            comment: "Information text when the survey is completed")
        static let needHelp = NSLocalizedString("Need some help?", comment: "Text preceding the Contact Us button in the survey completed screen")
        static let contactUs = NSLocalizedString("Contact us here", comment: "This text appears as the label for a button on the survey completion screen that allows users to contact customer support after submitting feedback. The button is displayed alongside other options like returning to the store after the user has successfully sent their survey response.")
        static let backToStore = NSLocalizedString("Back to store", comment: "This text appears as the title of a button on the survey completion screen that allows users to dismiss the screen and return to the main store interface after submitting feedback.")
        static let surveyAttributtion = NSLocalizedString("Powered by Automattic", comment: "Info text saying that crowdsignal in an Automattic product")
    }
}
