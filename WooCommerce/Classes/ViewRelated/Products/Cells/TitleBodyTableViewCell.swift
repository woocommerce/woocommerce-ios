import UIKit

final class TitleBodyTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        titleLabel?.applyHeadlineStyle()
        bodyLabel?.applySecondaryBodyStyle()
    }
}
