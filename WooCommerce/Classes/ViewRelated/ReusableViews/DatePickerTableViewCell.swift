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
        configureDatePicker()
    }
}


extension DatePickerTableViewCell {
    func getPicker() -> UIDatePicker {
        return picker
    }

    static func getDefaultCellHeight() -> CGFloat {
        if #available(iOS 14, *) {
            return CGFloat(380)
        }

        return CGFloat(216)
    }
}

private extension DatePickerTableViewCell {
    func configureBottomBorder() {
        bottomBorder.backgroundColor = .clear
    }

    func configureDatePicker() {
        if #available(iOS 14, *) {
            picker.preferredDatePickerStyle = .inline
        }
    }
}
