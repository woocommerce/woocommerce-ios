import UIKit


/// Represents a cell with a Title Label and Body Label
///
class TitleLabelTableViewCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel?
    @IBOutlet private weak var bodyLabel: UILabel?

    /// Title label text
    ///
    var title: String? {
        get {
            return titleLabel?.text
        }
        set {
            titleLabel?.text = newValue
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
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        titleLabel?.applyTitleStyle()
        bodyLabel?.applyBodyStyle()
    }
}
