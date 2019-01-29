import UIKit

class ApplicationLogDetailViewController: UIViewController {

    /// The contents of the log file.
    ///
    let logText: String

    /// The log file's creation date as a formatted string.
    ///
    let logDate: String


    // MARK: - Overridden Methods
    //
    
    /// Designated initializer
    ///
    init(with contents: String, for date: String) {
        self.logText = contents
        self.logDate = date

        super.init(nibName: nil, bundle: nil)
    }

    /// Unsupported: NSCoder
    ///
    required init?(coder aDecoder: NSCoder) {
        assertionFailure()
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureMainView()
    }

    /// Add styles and buttons to nav bar
    ///
    func configureNavigation() {
        title = NSLocalizedString("Application Log", comment: "Application Log navigation bar title - this screen is where users view a single log file.")

        // Don't show the Application Log title in the next-view's back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .plain, target: nil, action: nil)

        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(showShareActivity))
        navigationItem.rightBarButtonItem = shareButton
    }

    /// Apply Woo styles.
    ///
    func configureMainView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
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
    /// - returns: all supported types except `.copyToPasteboard` and `.mail`.
    ///
    func assembleExcludedSupportTypes() -> [UIActivity.ActivityType] {
        let activityTypes = NSMutableSet(array: SharingHelper.allActivityTypes())
        let unsupportedTypes = Set(arrayLiteral: [UIActivity.ActivityType.copyToPasteboard,
                                                  UIActivity.ActivityType.mail])

        activityTypes.minus(unsupportedTypes)

        return activityTypes.allObjects as! [UIActivity.ActivityType]
    }
}
