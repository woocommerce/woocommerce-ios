import UIKit

class NoResultsTableViewCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel?

    var title: String? {
        get {
            return titleLabel?.text
        }
        set {
            titleLabel?.text = newValue
        }
    }

    static let reuseIdentifier = "NoResultsTableViewCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel?.applyBodyStyle()
    }
}

extension NoResultsTableViewCell {
    func configure(text: String) {
        title = text
    }
}
