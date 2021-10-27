import UIKit

/// View Controller containing a configurable date picker.
///
final class DatePickerViewController: UIViewController {

    private let date: Date?
    private let datePickerMode: UIDatePicker.Mode

    @IBOutlet private weak var datePicker: UIDatePicker!

    init(date: Date? = nil, datePickerMode: UIDatePicker.Mode = .dateAndTime) {
        self.date = date
        self.datePickerMode = datePickerMode

        super.init(nibName: Self.nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.preferredDatePickerStyle = .inline
        datePicker.datePickerMode = datePickerMode

        guard let date = date else {
            return
        }
        datePicker.setDate(date, animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        datePicker.becomeFirstResponder()
    }
}
