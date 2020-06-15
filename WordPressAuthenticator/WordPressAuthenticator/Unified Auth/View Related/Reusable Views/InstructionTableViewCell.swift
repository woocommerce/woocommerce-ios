import UIKit


/// InstructionTableViewCell: a text label in a UITableViewCell.
///
public class InstructionTableViewCell: UITableViewCell {

    public static let reuseIdentifier = "InstructionTableViewCell"

    @IBOutlet public var instructionLabel: UILabel!

    public override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    public override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
