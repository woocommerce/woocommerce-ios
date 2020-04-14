import UIKit
import Yosemite

class ProductPurchaseNoteViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    
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
        let footerText = NSLocalizedString("An optional note to send the customer after purchase",
                                           comment: "Footer text in Product Purchase Note screen")
        sections = [Section(footer: footerText, rows: [.purchaseNote])]
        onCompletion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

}

// MARK: - Constants
//
private extension ProductPurchaseNoteViewController {

    /// Table Rows
    ///
    enum Row {
        /// Listed in the order they appear on screen
        case purchaseNote

        var reuseIdentifier: String {
            switch self {
            case .purchaseNote:
                return TextViewTableViewCell.reuseIdentifier
            }
        }
    }

    /// Table Sections
    ///
    struct Section {
        let footer: String?
        let rows: [Row]

        init(footer: String? = nil, rows: [Row]) {
            self.footer = footer
            self.rows = rows
        }
    }
}
