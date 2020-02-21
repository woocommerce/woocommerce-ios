import UIKit


/// Represents a cell with a Title Label and Body Label
///
final class HeadlineLabelTableViewCell: UITableViewCell {
    @IBOutlet private weak var headlineLabel: UILabel?
    @IBOutlet private weak var bodyLabel: UILabel?

    /// Headline label text
    ///
    var headline: String? {
        get {
            return headlineLabel?.text
        }
        set {
            headlineLabel?.text = newValue
            headlineLabel?.accessibilityIdentifier = "headline-label"
        }
    }

    /// Body label text
    ///
    var body: String? {
        get {
            return bodyLabel?.text
        }
        set {
            bodyLabel?.text = newValue
            bodyLabel?.accessibilityIdentifier = "body-label"
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
        configureHeadline()
        configureBody()
    }
}


private extension HeadlineLabelTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureHeadline() {
        headlineLabel?.applyHeadlineStyle()
    }

    func configureBody() {
        bodyLabel?.applyBodyStyle()
    }
}
