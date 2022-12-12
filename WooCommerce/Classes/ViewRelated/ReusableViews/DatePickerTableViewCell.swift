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

    override func prepareForReuse() {
        super.prepareForReuse()
        picker.minimumDate = nil
        picker.maximumDate = nil
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
        return CGFloat(50)
    }
}

private extension DatePickerTableViewCell {
    func configureBottomBorder() {
        bottomBorder.backgroundColor = .clear
    }

    func configureDatePicker() {
        picker.preferredDatePickerStyle = .compact
    }
}
