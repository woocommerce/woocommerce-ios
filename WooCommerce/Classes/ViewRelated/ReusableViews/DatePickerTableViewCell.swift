import UIKit

final class DatePickerTableViewCell: UITableViewCell {

    var onDateSelected: ((Date) -> Void)?

    @IBAction func dateChanged(_ sender: UIDatePicker) {
        onDateSelected?(sender.date)
    }
}
