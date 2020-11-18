import UIKit
import Yosemite

final class LinkedProductsViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private let viewModel: LinkedProductsViewModel
    // Completion callback
    //
    typealias Completion = (_ upsellIDs: [Int64],
                            _ crossSellIDs: [Int64],
                            _ hasUnsavedChanges: Bool) -> Void
    private let onCompletion: Completion

    /// Init
    ///
    init(product: ProductFormDataModel, completion: @escaping Completion) {
        viewModel = LinkedProductsViewModel()
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

extension LinkedProductsViewController {

    struct Section: Equatable {
        let title: String?
        let rows: [Row]
    }

    enum Row: CaseIterable {
        case price
        case salePrice

        case scheduleSale
        case scheduleSaleFrom
        case datePickerSaleFrom
        case scheduleSaleTo
        case datePickerSaleTo
        case removeSaleTo

        case taxStatus
        case taxClass

        fileprivate var type: UITableViewCell.Type {
            switch self {
            case .price, .salePrice:
                return UnitInputTableViewCell.self
            case .scheduleSale:
                return SwitchTableViewCell.self
            case .scheduleSaleFrom, .scheduleSaleTo:
                return SettingTitleAndValueTableViewCell.self
            case .datePickerSaleFrom, .datePickerSaleTo:
                return DatePickerTableViewCell.self
            case .taxStatus, .taxClass:
                return SettingTitleAndValueTableViewCell.self
            case .removeSaleTo:
                return BasicTableViewCell.self
            }
        }

        fileprivate var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}
