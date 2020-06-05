import UIKit


/// InstructionTableViewCell: a text label in a UITableViewCell.
///
class InstructionTableViewCell: UITableViewCell {

    @IBOutlet private weak var instructionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
