import UIKit

/// View Controller containing a configurable date picker.
///
final class DatePickerViewController: UIViewController {

    private let date: Date?
    private let datePickerMode: UIDatePicker.Mode
    private let minimumDate: Date? // specify min/max date range. default is nil. When min > max, the values are ignored. Ignored in countdown timer mode
    private let maximumDate: Date? // default is nil

    /// Completion callback
    ///
    typealias Completion = (_ date: Date?) -> Void
    private let onCompletion: Completion

    @IBOutlet private weak var datePicker: UIDatePicker!
    @IBOutlet weak var button: ButtonActivityIndicator!

    init(date: Date? = nil,
         datePickerMode: UIDatePicker.Mode = .dateAndTime,
         minimumDate: Date? = nil,
         maximumDate: Date? = nil,
         onCompletion: @escaping Completion) {
        self.date = date
        self.datePickerMode = datePickerMode
        self.minimumDate = minimumDate
        self.maximumDate = maximumDate
        self.onCompletion = onCompletion

        super.init(nibName: Self.nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureDatePicker()
        configureButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        datePicker.becomeFirstResponder()
    }

    @IBAction func buttonPressed(_ sender: Any) {
        onCompletion(datePicker.date)
    }
}

// MARK: - Configuration
private extension DatePickerViewController {
    func configureDatePicker() {
        datePicker.preferredDatePickerStyle = .inline
                datePicker.datePickerMode = datePickerMode
                datePicker.minimumDate = minimumDate
                datePicker.maximumDate = maximumDate
        guard let date = date else {
            return
        }
        datePicker.setDate(date, animated: false)
    }

    func configureButton() {
        button.setTitle(Localization.doneButton, for: .normal)
        button.applySecondaryButtonStyle()
    }
}

private extension DatePickerViewController {
    enum Localization {
        static let doneButton = NSLocalizedString("Done", comment: "Done button in Date Picker View")
    }
}
