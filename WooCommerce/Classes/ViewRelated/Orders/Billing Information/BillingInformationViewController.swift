import UIKit
import Yosemite


/// Renders the Order Billing Information Interface
///
final class BillingInformationViewController: UIViewController {
    
    /// Main TableView
    ///
    @IBOutlet weak var tableView: UITableView!
    
    /// Sections to be Rendered
    ///
    private var sections = [Section]()
    
    /// Order to be Fulfilled
    ///
    private let order: Order
    
    
    /// Designated Initializer
    ///
    init(order: Order) {
        self.order = order
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }
    
    /// NSCoder Conformance
    ///
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationItem()
        setupMainView()
        registerTableViewCells()
        registerTableViewHeaderFooters()
        reloadSections()
    }
    
}

// MARK: - Interface Initialization
//
private extension BillingInformationViewController {
    
    /// Setup: Navigation Item
    ///
    func setupNavigationItem() {
        title = NSLocalizedString("Billing Information", comment: "Billing Information view Title")
    }
    
    /// Setup: Main View
    ///
    func setupMainView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.estimatedSectionHeaderHeight = Constants.sectionHeight
        tableView.estimatedSectionFooterHeight = Constants.rowHeight
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        let cells = [
            CustomerInfoTableViewCell.self,
            WooBasicTableViewCell.self
        ]
        
        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }
    
    /// Registers all of the available TableViewHeaderFooters
    ///
    func registerTableViewHeaderFooters() {
        let headersAndFooters = [ TwoColumnSectionHeaderView.self ]
        
        for kind in headersAndFooters {
            tableView.register(kind.loadNib(), forHeaderFooterViewReuseIdentifier: kind.reuseIdentifier)
        }
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension BillingInformationViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        
        setup(cell: cell, for: row, at: indexPath)
        
        return cell
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension BillingInformationViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let leftText = sections[section].title else {
            return nil
        }
        
        let headerID = TwoColumnSectionHeaderView.reuseIdentifier
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerID) as? TwoColumnSectionHeaderView else {
            fatalError()
        }
        
        headerView.leftText = leftText
        headerView.rightText = sections[section].secondaryTitle
        
        return headerView
    }
    
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//        tableView.selectRow(at: <#T##IndexPath?#>, animated: <#T##Bool#>, scrollPosition: <#T##UITableView.ScrollPosition#>)
//        viewModel.tableView(tableView, in: self, didSelectRowAt: indexPath)
//    }
//
//    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
//        // No trailing action on any cell
//        return UISwipeActionsConfiguration(actions: [])
//    }
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//
//        switch sections[indexPath.section].rows[indexPath.row] {
//
//        case .trackingAdd:
//            WooAnalytics.shared.track(.orderFulfillmentAddTrackingButtonTapped)
//
//            let viewModel = AddTrackingViewModel(order: order)
//            let addTracking = ManualTrackingViewController(viewModel: viewModel)
//            let navController = WooNavigationController(rootViewController: addTracking)
//            present(navController, animated: true, completion: nil)
//
//        case .product(let item):
//            let productIDToLoad = item.variationID == 0 ? item.productID : item.variationID
//            productWasPressed(for: productIDToLoad)
//
//        case .tracking:
//            break
//
//        default:
//            break
//        }
//    }
}

// MARK: - Cell Configuration
//
private extension BillingInformationViewController {
    
    /// Setup a given UITableViewCell instance to actually display the specified Row's Payload.
    ///
    func setup(cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as CustomerInfoTableViewCell where row == .billingAddress:
            setupBillingAddress(cell: cell)
        case let cell as WooBasicTableViewCell where row == .billingPhone:
            setupBillingPhone(cell: cell)
        case let cell as WooBasicTableViewCell where row == .billingEmail:
            setupBillingEmail(cell: cell)
        default:
            fatalError("Unidentified customer info row type")
        }
    }
    
    /// Setup: Billing Address Cell
    ///
    func setupBillingAddress(cell: CustomerInfoTableViewCell) {
        let billingAddress = order.billingAddress
        
        cell.title = NSLocalizedString("Billing details", comment: "Billing title for customer info cell")
        cell.name = billingAddress?.fullNameWithCompany
        cell.address = billingAddress?.formattedPostalAddress ??
            NSLocalizedString("No address specified.",
                              comment: "Order details > customer info > billing details. This is where the address would normally display.")
    }
    
    func setupBillingPhone(cell: WooBasicTableViewCell) {
        guard let phoneNumber = order.billingAddress?.phone else {
            return
        }
        
        cell.bodyLabel?.text = phoneNumber
        cell.bodyLabel?.applyBodyStyle()
        cell.accessoryImage = .ellipsisImage
        
        cell.isAccessibilityElement = true
        cell.accessibilityTraits = .button
        cell.accessibilityLabel = String.localizedStringWithFormat(
            NSLocalizedString(
                "Phone number: %@",
                comment: "Accessibility label that lets the user know the data is a phone number before speaking the phone number."
            ),
            phoneNumber
        )
        
        cell.accessibilityHint = NSLocalizedString(
            "Prompts with the option to call or message the billing customer.",
            comment: "VoiceOver accessibility hint, informing the user that the row can be tapped to call or message the billing customer."
        )
    }
    
    func setupBillingEmail(cell: WooBasicTableViewCell) {
        guard let email = order.billingAddress?.email else {
            return
        }
        
        cell.bodyLabel?.text = email
        cell.bodyLabel?.applyBodyStyle()
        cell.accessoryImage = .mailImage
        
        cell.isAccessibilityElement = true
        cell.accessibilityTraits = .button
        cell.accessibilityLabel = String.localizedStringWithFormat(
            NSLocalizedString("Email: %@",
                              comment: "Accessibility label that lets the user know the billing customer's email address"),
            email
        )
        
        cell.accessibilityHint = NSLocalizedString(
            "Composes a new email message to the billing customer.",
            comment: "Accessibility hint, informing that a row can be tapped and an email composer view will appear."
        )
    }
    
    
    
}

// MARK: - Table view sections
//
private extension BillingInformationViewController {
    func reloadSections() {
        let billingAddress: Section = {
            let title = NSLocalizedString("Billing Address", comment: "Section header title for billing address in billing information")
            return Section(title: title, secondaryTitle: nil, rows: [.billingAddress])
        }()
        
        let contactDetails: Section? = {
            guard let address = order.billingAddress else {
                return nil
            }
            
            var rows: [Row] = []
            
            if address.hasPhoneNumber {
                rows.append(.billingPhone)
            }
            if address.hasEmailAddress {
                rows.append(.billingEmail)
            }
            
            let title = NSLocalizedString("Contact Details", comment: "Section header title for contact details in billing information")
            return Section(title: title, secondaryTitle: nil, rows: rows)
        }()
        
        sections =  [billingAddress, contactDetails].compactMap { $0 }
    }
}

// MARK: - Section: Represents a TableView Section
//
private struct Section {
    
    /// Section's Title
    ///
    let title: String?
    
    /// Section's Secondary Title
    ///
    let secondaryTitle: String?
    
    /// Section's Row(s)
    ///
    let rows: [Row]
}

// MARK: - Row: Represents a TableView Row
//
private enum Row {
    
    /// Represents an address row
    ///
    case billingAddress
    
    /// Represents a phone row
    ///
    case billingPhone
    
    /// Represents an email row
    ///
    case billingEmail
    
    /// Returns the Row's Reuse Identifier
    ///
    var reuseIdentifier: String {
        return cellType.reuseIdentifier
    }
    
    /// Returns the Row's Cell Type
    ///
    var cellType: UITableViewCell.Type {
        switch self {
        case .billingAddress:
            return CustomerInfoTableViewCell.self
        case .billingPhone:
            return WooBasicTableViewCell.self
        case .billingEmail:
            return WooBasicTableViewCell.self
        }
    }
}

// MARK: - Constants
//
private extension BillingInformationViewController {
    
    enum Constants {
        static let rowHeight = CGFloat(38)
        static let sectionHeight = CGFloat(44)
    }
}
