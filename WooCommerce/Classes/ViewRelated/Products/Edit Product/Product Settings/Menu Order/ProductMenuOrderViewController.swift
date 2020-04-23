import UIKit
import Yosemite

final class ProductMenuOrderViewController: UIViewController {

    @IBOutlet weak private var tableView: UITableView!
    
    // Completion callback
    //
    typealias Completion = (_ productSettings: ProductSettings) -> Void
    private let onCompletion: Completion

    private let productSettings: ProductSettings

    private let sections: [Section]

    /// Init
    ///
    init(settings: ProductSettings, completion: @escaping Completion) {
        productSettings = settings
        let footerText = NSLocalizedString("Determines the products positioning in the catalog. The lower the value of the number, the higher the item will be on the product list. You can also use negative values",
                                           comment: "Footer text in Product Menu order screen")
        sections = [Section(footer: footerText, rows: [.menuOrder])]
        onCompletion = completion
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

}


// MARK: - Constants
//
private extension ProductMenuOrderViewController {

    /// Table Rows
    ///
    enum Row {
        /// Listed in the order they appear on screen
        case menuOrder

        var reuseIdentifier: String {
            switch self {
            case .menuOrder:
                return TextFieldTableViewCell.reuseIdentifier
            }
        }
    }

    /// Table Sections
    ///
    struct Section: RowIterable {
        let footer: String?
        let rows: [Row]

        init(footer: String? = nil, rows: [Row]) {
            self.footer = footer
            self.rows = rows
        }
    }
}
