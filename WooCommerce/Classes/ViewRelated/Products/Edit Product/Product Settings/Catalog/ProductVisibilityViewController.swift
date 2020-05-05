import UIKit
import Yosemite

final class ProductVisibilityViewController: UIViewController {

    @IBOutlet weak private var tableView: UITableView!

    // Completion callback
    //
    typealias Completion = (_ productSettings: ProductSettings) -> Void
    private let onCompletion: Completion

    private let productSettings: ProductSettings

    override func viewDidLoad() {
        super.viewDidLoad()


    }

    /// Init
    ///
    init(settings: ProductSettings, completion: @escaping Completion) {
        productSettings = settings
        onCompletion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: - Constants
//
extension ProductVisibilityViewController {

    /// Table Rows
    ///
    enum Row {
        /// Listed in the order they appear on screen
        case publicVisibility
        case passwordVisibility
        case passwordField
        case privateVisibility

        var reuseIdentifier: String {
            switch self {
            case .publicVisibility, .passwordVisibility, .passwordField, .privateVisibility:
                return BasicTableViewCell.reuseIdentifier
            }
        }

        var description: String {
            switch self {
            case .publicVisibility:
                return NSLocalizedString("Public", comment: "One of the possible options in Product Visibility")
            case .passwordVisibility:
                return NSLocalizedString("Password Protected", comment: "One of the possible options in Product Visibility")
            case .passwordField:
                return NSLocalizedString("Password", comment: "One of the possible options in Product Visibility")
            case .privateVisibility:
                return NSLocalizedString("Private", comment: "One of the possible options in Product Visibility")
            }
        }
    }

    /// Table Sections
    ///
    struct Section {
        let rows: [Row]

        init(rows: [Row]) {
            self.rows = rows
        }

        init(row: Row) {
            self.init(rows: [row])
        }
    }
}
