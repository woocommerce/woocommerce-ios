import UIKit

/// Cell containing a UIDatePicker, configured as Year / Month / Day
///
final class DatePickerTableViewCell: UITableViewCell {

    var onDateSelected: ((Date) -> Void)?
    @IBOutlet private weak var picker: UIDatePicker!

    @IBAction func dateChanged(_ sender: UIDatePicker) {
        onDateSelected?(sender.date)
    }
}

extension DatePickerTableViewCell {
    func getPicker() -> UIDatePicker {
        return picker
    }
}
