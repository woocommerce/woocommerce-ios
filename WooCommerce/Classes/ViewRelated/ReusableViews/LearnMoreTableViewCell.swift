import UIKit

/// A table view cell that, when tapped, opens a URL where users can "learn more" about something.
class LearnMoreTableViewCell: UITableViewCell {

    @IBOutlet weak var learnMoreLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
