import UIKit
import Yosemite

class AddaNoteViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet var tableView: UITableView!

    var order: Order!

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureTableView()
    }

    func configureNavigation() {
        title = NSLocalizedString("Order #\(order.number)", comment: "Add a note screen - title. Example: Order #15")

        let dismissButtonTitle = NSLocalizedString("Dismiss", comment: "Add a note screen - button title for closing the view")
        let leftBarButton = UIBarButtonItem(title: dismissButtonTitle,
                                            style: .plain,
                                            target: self,
                                            action: #selector(dismissButtonTapped))
        leftBarButton.tintColor = .white
        navigationItem.setLeftBarButton(leftBarButton, animated: false)

        let addButtonTitle = NSLocalizedString("Add", comment: "Add a note screen - button title to send the note")
        let rightBarButton = UIBarButtonItem(title: addButtonTitle,
                                             style: .done,
                                             target: self,
                                             action: #selector(addButtonTapped))
        rightBarButton.tintColor = .white
        navigationItem.setRightBarButton(rightBarButton, animated: false)
    }

    @objc func dismissButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc func addButtonTapped() {
        NSLog("Add button tapped!")
    }
}

// MARK: - TableView Configuration
//
private extension AddaNoteViewController {
    /// Setup: TableView
    ///
    func configureTableView() {
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension AddaNoteViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return NSLocalizedString("WRITE NOTE", comment: "Add a note screen - Write Note section title")
        }

        return ""
    }
}

// MARK: - Constants
//
private extension AddaNoteViewController {
    struct Constants {
        static let rowHeight = CGFloat(44)
    }
}
