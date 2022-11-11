import UIKit

/// Displays a  button to issue new refunds.
///
final class IssueRefundTableViewCell: UITableViewCell {
    @IBOutlet private var issueRefundButton: UIButton!

    var onIssueRefundTouchUp: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureIssueRefundButton()
    }
}

// MARK: Actions
extension IssueRefundTableViewCell {
    @IBAction func issueRefundWasPressed() {
        onIssueRefundTouchUp?()
    }
}

// MARK: View Configuration
private extension IssueRefundTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureIssueRefundButton() {
        issueRefundButton.applySecondaryButtonStyle()
        // Testing: Remove before submitting for review
        issueRefundButton.backgroundColor = .yellow
        issueRefundButton.layer.borderColor = CGColor(red: 1, green: 0, blue: 0, alpha: 1)
        issueRefundButton.layer.borderWidth = 2.0
        //
        issueRefundButton.setTitle(Localization.buttonTitle, for: .normal)
    }
}

// MARK: Localization
private extension IssueRefundTableViewCell {
    enum Localization {
        static let buttonTitle = NSLocalizedString("Issue Refund", comment: "Text on the button that starts a new refund process")
    }
}
