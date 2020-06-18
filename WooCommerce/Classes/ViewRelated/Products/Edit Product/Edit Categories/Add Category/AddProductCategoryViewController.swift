import UIKit

/// AddProductCategoryViewController: Add a new category associated to the active Account.
///
final class AddProductCategoryViewController: UIViewController {

    init() {
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }
}


// MARK: - Private Types
//
private extension AddProductCategoryViewController {

    struct Section {
        let rows: [Row]
    }

    enum Row: CaseIterable {
        case title
        case parentCategory

        var type: UITableViewCell.Type {
            switch self {
            case .title:
                return UnitInputTableViewCell.self
            case .parentCategory:
                return SwitchTableViewCell.self
            }
        }

        var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}
