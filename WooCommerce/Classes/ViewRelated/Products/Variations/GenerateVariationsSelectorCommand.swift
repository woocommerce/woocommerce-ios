import UIKit

/// `GenerateVariationsSelectorCommand` for selecting what create variation strategy to follow
///
final class GenerateVariationsSelectorCommand: BottomSheetListSelectorCommand {

    /// Available Generation Options
    ///
    enum Options: CaseIterable {
        case single
        case all

        var title: String {
            switch self {
            case .single:
                return Localization.singleTitle
            case .all:
                return Localization.allTitle
            }
        }

        var description: String {
            switch self {
            case .single:
                return Localization.singleDescription
            case .all:
                return Localization.allDescription
            }
        }
    }

    let data = Options.allCases
    var selected: Options? = nil
    private let onSelection: (Options) -> Void

    init(selected: Options?, onSelection: @escaping (Options) -> Void) {
        self.onSelection = onSelection
        self.selected = selected
    }

    func configureCell(cell: ImageAndTitleAndTextTableViewCell, model: Options) {
        let viewModel = ImageAndTitleAndTextTableViewCell.ViewModel(title: model.title,
                                                                    text: model.description,
                                                                    numberOfLinesForText: 0,
                                                                    isSelected: isSelected(model: model)
        )
        cell.updateUI(viewModel: viewModel)
    }

    func handleSelectedChange(selected: Options) {
        onSelection(selected)
    }

    func isSelected(model: Options) -> Bool {
        return model == selected
    }
}

private extension GenerateVariationsSelectorCommand {
    enum Localization {
        static let singleTitle = NSLocalizedString("Add new variation", comment: "Title for the option to generate just one variation")
        static let singleDescription = NSLocalizedString("Create one new variation. Manually set which attributes belong to the variable product.",
                                                         comment: "Description for the option to generate just one variation")
        static let allTitle = NSLocalizedString("Generate all variations", comment: "Title for the option to generate all possible variations")
        static let allDescription = NSLocalizedString("Creates variations for all combinations of your attributes.",
                                                      comment: "Description for the option to generate all possible variations")

    }
}
