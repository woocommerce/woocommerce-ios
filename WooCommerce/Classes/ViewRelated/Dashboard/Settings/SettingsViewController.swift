import UIKit


// MARK: - SettingsViewController
//
class SettingsViewController: UIViewController {

    // MARK: - Properties
    @IBOutlet weak var tableView: UITableView!

    let sectionTitles = [""]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Settings", comment: "Settings navigation title")
        setupTableView()
    }

    func setupTableView() {
        // `tableView.tableFooterView` can't handle a footerView that uses
        // autolayout only. Hence the container view with a defined frame.
        let footerContainer = UIView(frame: CGRect(x: 0, y: 0, width: Int(self.tableView.frame.width), height: Constants.footerHeight))
        let footerView = SettingsFooterView.makeFromNib()
        self.tableView.tableFooterView = footerContainer
        footerContainer.addSubview(footerView)
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sectionTitles.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sectionTitles[section]
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension SettingsViewController: UITableViewDelegate {

}

// MARK: - Constants
//
private extension SettingsViewController {
    struct Constants {
        static let footerHeight = 90
    }
}
