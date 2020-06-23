import UIKit


/// InstructionTableViewCell: a text label in a UITableViewCell.
///
public final class InstructionTableViewCell: UITableViewCell {

    /// Private properties
    ///
    @IBOutlet private weak var instructionLabel: UILabel!

    /// Public properties
    ///
    public static let reuseIdentifier = "InstructionTableViewCell"

    public var instructionText: String? {
        get {
            return instructionLabel.text
        }
        set {
            instructionLabel.text = newValue
        }
    }
}
