import UIKit

// MARK: - ApplicationLogViewController
//
class ApplicationLogViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
    }

    func configureNavigation() {
        title = NSLocalizedString("Activity Log", comment: "Activity Log navigation bar title")

        // Don't show the Help & Support title in the next-view's back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .plain, target: nil, action: nil)
    }
}
