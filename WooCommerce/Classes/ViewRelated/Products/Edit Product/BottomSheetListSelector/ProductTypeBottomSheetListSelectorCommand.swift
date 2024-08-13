import Yosemite

/// `BottomSheetListSelectorCommand` for selecting a product type for the selected Product.
///
final class ProductTypeBottomSheetListSelectorCommand: BottomSheetListSelectorCommand {
    typealias Model = BottomSheetProductType
    typealias Cell = ImageAndTitleAndTextTableViewCell

    enum Source {
        case creationForm
        case editForm(selected: BottomSheetProductType)
    }

    var data: [BottomSheetProductType] {
        let defaultOptions: [BottomSheetProductType] = [
            .simple(isVirtual: false),
            .simple(isVirtual: true),
            isEligibleForSubscriptionProducts ? .subscription : nil,
            .variable,
            isEligibleForSubscriptionProducts ? .variableSubscription : nil,
            .grouped,
            .affiliate
        ].compactMap { $0 }

        switch source {
        case .creationForm:
            return defaultOptions
        case .editForm(let selected):
            return defaultOptions.filter { $0 != selected }
        }
    }

    let selected: BottomSheetProductType?

    private let source: Source
    private let onSelection: (BottomSheetProductType) -> Void
    private let isEligibleForSubscriptionProducts: Bool

    init(source: Source,
         subscriptionProductsEligibilityChecker: WooSubscriptionProductsEligibilityCheckerProtocol,
         onSelection: @escaping (BottomSheetProductType) -> Void) {
        self.source = source
        self.onSelection = onSelection
        self.isEligibleForSubscriptionProducts = subscriptionProductsEligibilityChecker.isSiteEligible()
        if case let .editForm(selected) = source {
            self.selected = selected
        } else {
            self.selected = nil
        }
    }

    func configureCell(cell: ImageAndTitleAndTextTableViewCell, model: BottomSheetProductType) {
        let viewModel = ImageAndTitleAndTextTableViewCell.ViewModel(title: model.actionSheetTitle,
                                                                    text: model.actionSheetDescription,
                                                                    image: model.actionSheetImage,
                                                                    imageTintColor: .gray(.shade20),
                                                                    numberOfLinesForText: 0)
        cell.updateUI(viewModel: viewModel)
    }

    func handleSelectedChange(selected: BottomSheetProductType) {
        onSelection(selected)
    }

    func isSelected(model: BottomSheetProductType) -> Bool {
        return model == selected
    }
}
