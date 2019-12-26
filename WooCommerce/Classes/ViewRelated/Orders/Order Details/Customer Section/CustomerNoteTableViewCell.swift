import UIKit

final class CustomerNoteTableViewCell: UITableViewCell {

    @IBOutlet private weak var headlineLabel: UILabel!

    @IBOutlet private weak var bodyLabel: UILabel!

    /// Headline label text
    ///
    var headline: String? {
        get {
            return headlineLabel.text
        }
        set {
            headlineLabel.text = newValue
        }
    }

    /// Body label text
    ///
    var body: String? {
        get {
            return bodyLabel.text
        }
        set {
            bodyLabel.text = newValue
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureLabels()
    }

}


// MARK: - Private Methods
//
private extension CustomerNoteTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureLabels() {
        headlineLabel.applyHeadlineStyle()
        bodyLabel.applyBodyStyle()
    }
}


/// MARK: - Testability
extension CustomerNoteTableViewCell {
    func getHeadlineLabel() -> UILabel {
        return headlineLabel
    }

    func getBodyLabel() -> UILabel {
        return bodyLabel
    }
}
