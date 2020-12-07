import UIKit

final class OrderFormViewController: UIViewController {

    /// Main TableView.
    ///
    private lazy var tableView = UITableView(frame: .zero, style: .grouped)
    private let dataSource: OrderFormDataSource = .init()

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureTableView()
    }

    @objc func presentMoreOptionsActionSheet(_ sender: UIBarButtonItem) {
        // TODO: show option to save a draft
    }
}

// MARK: - User Interface Initialization
//
private extension OrderFormViewController {

    func configureNavigation() {
        title = Localization.newOrderTitle

        navigationItem.rightBarButtonItem = createMoreOptionsBarButtonItem()
    }

    func createMoreOptionsBarButtonItem() -> UIBarButtonItem {
        let moreButton = UIBarButtonItem(image: .moreImage,
                                         style: .plain,
                                         target: self,
                                         action: #selector(presentMoreOptionsActionSheet(_:)))
        moreButton.accessibilityLabel = Localization.moreOptionsAccessibilityLabel
        return moreButton
    }

    func configureTableView() {
        dataSource.registerTableViewCells(tableView)

        tableView.delegate = self
        tableView.dataSource = dataSource

        view.backgroundColor = .listBackground
        tableView.backgroundColor = .listBackground
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = .leastNonzeroMagnitude
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = UITableView.automaticDimension

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.pinSubviewToSafeArea(tableView)
    }
}

// MARK: - UITableViewDelegate
//
extension OrderFormViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // TODO: handle actions
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        dataSource.heightForHeaderInSection(section, tableView: tableView)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        dataSource.viewForHeaderInSection(section, tableView: tableView)
    }
}

private extension OrderFormViewController {
    enum Localization {
        static let newOrderTitle = NSLocalizedString("New Order", comment: "Title for `Create Order` screen.")
        static let moreOptionsAccessibilityLabel = NSLocalizedString("More options",
                                                                     comment: "Accessibility label for `Add Order` More Options action sheet")
    }
}
