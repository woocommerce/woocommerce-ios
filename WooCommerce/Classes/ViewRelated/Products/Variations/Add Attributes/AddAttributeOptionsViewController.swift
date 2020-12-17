import UIKit

final class AddAttributeOptionsViewController: UIViewController {

    private let viewModel: AddAttributeOptionsViewModel

    /// Init
    ///
    init(viewModel: AddAttributeOptionsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }
}

extension AddAttributeOptionsViewController {

    struct Section: Equatable {
        let header: String?
        let footer: String?
        let rows: [Row]
    }

    enum Row: CaseIterable {
        case termTextField
        case selectedTerms
        case existingTerms

        fileprivate var type: UITableViewCell.Type {
            switch self {
            case .termTextField:
                return TextFieldTableViewCell.self
            case .selectedTerms:
                return BasicTableViewCell.self
            case .existingTerms:
                return BasicTableViewCell.self
            }
        }

        fileprivate var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}
