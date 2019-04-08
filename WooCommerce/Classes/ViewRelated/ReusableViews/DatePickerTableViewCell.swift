import UIKit

final class DatePickerTableViewCell: UITableViewCell {

    @IBAction func dateChanged(_ sender: UIDatePicker) {
        print("==== new date ==== ", sender.date)
    }
}
