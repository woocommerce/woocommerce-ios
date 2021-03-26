import UIKit

class ApplicationLogDetailViewController: UIViewController {

    /// The contents of the log file.
    ///
    var logText: String

    /// The log file's creation date as a formatted string.
    ///
    var logDate: String

    /// The textview for displaying the log data
    ///
    @IBOutlet private var textview: UITextView!


    // MARK: - Overridden Methods
    //

    /// Designated initializer
    ///
    init(with contents: String, for date: String) {
        self.logText = contents
        self.logDate = date

        super.init(nibName: "ApplicationLogDetailViewController", bundle: Bundle.main)
    }

    required init?(coder aDecoder: NSCoder) {
        self.logText = ""
        self.logDate = ""
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureMainView()
        textview.text = logText
    }

    /// Add styles and buttons to nav bar
    ///
    func configureNavigation() {
        title = logDate

        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(showShareActivity))
        navigationItem.rightBarButtonItem = shareButton
    }

    /// Apply Woo styles.
    ///
    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    /// Display the share activity
    /// Uses @objc attribute because this function is called from a #selector
    ///
    @objc
    func showShareActivity(_ sender: UIBarButtonItem) {
        let activityVC = UIActivityViewController(activityItems: [logText], applicationActivities: nil)
        activityVC.modalPresentationStyle = .popover
        activityVC.popoverPresentationController?.barButtonItem = sender
        activityVC.excludedActivityTypes = assembleExcludedSupportTypes()
        present(activityVC, animated: true, completion: nil)
    }

    /// Specifies the activity types that should be excluded.
    /// - returns: all unsupported types
    /// Preserves support for `.copyToPasteboard`, `.mail`, and `.airDrop`
    ///
    func assembleExcludedSupportTypes() -> [UIActivity.ActivityType] {
        let activityTypes = NSMutableSet(array: SharingHelper.allActivityTypes())

        /*
         * Don't use Set(arrayLiteral:) here, because it will convert the enums to the raw string value,
         * which would be wrong, because the allActivityTypes listed above are stored as enum types.
         */
        let supportedTypes = NSSet(objects: UIActivity.ActivityType.copyToPasteboard,
                                            UIActivity.ActivityType.mail,
                                            UIActivity.ActivityType.airDrop)

        // Now you can downcast to Set, because the type was preserved on init of the NSSet.
        activityTypes.minus(supportedTypes as! Set<AnyHashable>)

        return activityTypes.allObjects as! [UIActivity.ActivityType]
    }
}
