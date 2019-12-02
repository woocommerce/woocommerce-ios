import UIKit

/// Cell containing a UIDatePicker, configured as Year / Month / Day
///
final class DatePickerTableViewCell: UITableViewCell {

    var onDateSelected: ((Date) -> Void)?
    @IBOutlet private weak var picker: UIDatePicker!

    @IBOutlet weak var bottomBorder: UIView!

    @IBAction func dateChanged(_ sender: UIDatePicker) {
        onDateSelected?(sender.date)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBottomBorder()
    }

    private func configureBottomBorder() {
        bottomBorder.backgroundColor = UIColor.listSmallIcon
    }
}


extension DatePickerTableViewCell {
    func getPicker() -> UIDatePicker {
        return picker
    }
}
