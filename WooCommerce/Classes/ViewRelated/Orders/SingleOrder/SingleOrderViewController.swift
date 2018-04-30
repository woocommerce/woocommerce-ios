import UIKit

class SingleOrderViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var order: Order!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Order #\(order.number)", comment:"Order number title")
        let nib = UINib(nibName: SingleOrderSummaryCell.reuseIdentifier, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: SingleOrderSummaryCell.reuseIdentifier)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
         setupNavigationBar()
    }
}

extension SingleOrderViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SingleOrderSummaryCell.reuseIdentifier, for: indexPath) as! SingleOrderSummaryCell
        cell.configureCell(order: order)
        return cell
    }
}

extension SingleOrderViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension SingleOrderViewController {
    func setupNavigationBar() {
        // Don't show the Order title in the next-view's back button
        let backButton = UIBarButtonItem(title: String(),
                                         style: .plain,
                                         target: nil,
                                         action: nil)

        navigationItem.backBarButtonItem = backButton
    }
}
