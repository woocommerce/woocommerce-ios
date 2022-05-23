import Foundation
import Yosemite

/// `BottomSheetListSelectorCommand` for selecting a discount type for a coupon.
///
final class DiscountTypeBottomSheetListSelectorCommand: BottomSheetListSelectorCommand {
    typealias Model = Coupon.DiscountType
    typealias Cell = ImageAndTitleAndTextTableViewCell

    var data: [Coupon.DiscountType] = [
        .percent,
        .fixedCart,
        .fixedProduct
    ]

    var selected: Coupon.DiscountType? = nil

    private let onSelection: (Coupon.DiscountType) -> Void

    init(selected: Coupon.DiscountType?, onSelection: @escaping (Coupon.DiscountType) -> Void) {
        self.onSelection = onSelection

        /// Remove from `data` the selected discount type, so that it is not shown in the list.
        data.removeAll { (productType) -> Bool in
            productType == selected
        }
    }

    func configureCell(cell: ImageAndTitleAndTextTableViewCell, model: Coupon.DiscountType) {
        let viewModel = ImageAndTitleAndTextTableViewCell.ViewModel(title: model.localizedName,
                                                                    text: model.actionSheetDescription,
                                                                    image: model.actionSheetIcon,
                                                                    imageTintColor: .gray(.shade20),
                                                                    numberOfLinesForText: 0,
                                                                    isActionable: false)
        cell.updateUI(viewModel: viewModel)
    }

    func handleSelectedChange(selected: Coupon.DiscountType) {
        onSelection(selected)
    }

    func isSelected(model: Coupon.DiscountType) -> Bool {
        return model == selected
    }
}
