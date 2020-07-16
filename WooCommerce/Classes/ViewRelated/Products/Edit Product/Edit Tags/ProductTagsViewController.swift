import UIKit
import Yosemite

class ProductTagsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    // Completion callback
    //
    typealias Completion = (_ tags: [ProductTag]) -> Void
    private let onCompletion: Completion

    init(product: Product, completion: @escaping Completion) {
        onCompletion = completion
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: - Constants
//
private extension ProductTagsViewController {

    /// Table Rows
    ///
    enum Row {
        /// Listed in the order they appear on screen
        case tagsTextField
        case tag

        var reuseIdentifier: String {
            switch self {
            case .tagsTextField:
                return TextFieldTableViewCell.reuseIdentifier
            case .tag:
                return BasicTableViewCell.reuseIdentifier
            }
        }
    }

    /// Table Sections
    ///
    struct Section: RowIterable {
        let rows: [Row]

        init(rows: [Row]) {
            self.rows = rows
        }
    }
}
