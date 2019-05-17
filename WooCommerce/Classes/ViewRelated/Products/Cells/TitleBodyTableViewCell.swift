import UIKit

final class TitleBodyTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var secondBodyLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        titleLabel?.applyHeadlineStyle()

        bodyLabel?.applySecondaryBodyStyle()
        bodyLabel?.lineBreakMode = .byWordWrapping
        bodyLabel?.numberOfLines = 0

        secondBodyLabel?.applySecondaryBodyStyle()
        secondBodyLabel?.lineBreakMode = .byWordWrapping
        secondBodyLabel?.numberOfLines = 0
    }
}
