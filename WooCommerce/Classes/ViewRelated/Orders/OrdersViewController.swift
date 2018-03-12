import UIKit

class OrdersViewController: UIViewController, UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = NSLocalizedString("Orders", comment: "Orders title")
        self.navigationController?.navigationBar.barTintColor = ThemeColors.wooCommercePurple
    }

    // MARK - Tableview 

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1;
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}
