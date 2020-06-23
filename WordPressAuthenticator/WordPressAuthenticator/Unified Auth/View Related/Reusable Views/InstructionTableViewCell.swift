import UIKit


/// InstructionTableViewCell: a text label in a UITableViewCell.
///
public final class InstructionTableViewCell: UITableViewCell {

    public static let reuseIdentifier = "InstructionTableViewCell"
    @IBOutlet private weak var instructionLabel: UILabel!

    public var instructionText: String? {
        get {
            return instructionLabel.text
        }
        set {
            instructionLabel.text = newValue
        }
    }
}
