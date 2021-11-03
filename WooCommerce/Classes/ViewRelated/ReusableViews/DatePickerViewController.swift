import UIKit

/// View Controller containing a configurable date picker.
///
final class DatePickerViewController: UIViewController {

    private let date: Date?
    private let datePickerMode: UIDatePicker.Mode
    private let minimumDate: Date? // specify min/max date range. default is nil. When min > max, the values are ignored. Ignored in countdown timer mode
    private let maximumDate: Date? // default is nil

    @IBOutlet private weak var datePicker: UIDatePicker!

    init(date: Date? = nil,
         datePickerMode: UIDatePicker.Mode = .dateAndTime,
         minimumDate: Date? = nil,
         maximumDate: Date? = nil) {
        self.date = date
        self.datePickerMode = datePickerMode
        self.minimumDate = minimumDate
        self.maximumDate = maximumDate

        super.init(nibName: Self.nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.preferredDatePickerStyle = .inline
        datePicker.datePickerMode = datePickerMode
        datePicker.minimumDate = minimumDate
        datePicker.maximumDate = maximumDate

        guard let date = date else {
            return
        }
        datePicker.setDate(date, animated: false)

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Localization.doneButton,
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(doneButtonPressed))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        datePicker.becomeFirstResponder()
    }

    @objc private func doneButtonPressed() {

    }
}

private extension DatePickerViewController {
    enum Localization {
        static let doneButton = NSLocalizedString("Done", comment: "Done button in Date Picker View")
    }
}
