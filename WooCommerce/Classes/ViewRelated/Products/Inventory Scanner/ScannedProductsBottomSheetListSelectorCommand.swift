import Foundation

struct ScannedProductsBottomSheetListSelectorCommand: BottomSheetListSelectorCommand {
    typealias Model = ProductSKUScannerResult
    typealias Cell = ProductsTabProductTableViewCell

    let data: [ProductSKUScannerResult]

    let selected: ProductSKUScannerResult? = nil

    private let imageService: ImageService
    private let onSelection: (ProductSKUScannerResult) -> Void

    init(results: [ProductSKUScannerResult],
         imageService: ImageService = ServiceLocator.imageService,
         onSelection: @escaping (ProductSKUScannerResult) -> Void) {
        self.onSelection = onSelection
        self.imageService = imageService
        self.data = results
    }

    func configureCell(cell: ProductsTabProductTableViewCell, model: ProductSKUScannerResult) {
        cell.selectionStyle = .none
        cell.accessoryType = .disclosureIndicator

        // TODO-jc: stock quantity tracking
        switch model {
        case .matched(let product):
            cell.configureForInventoryScannerResult(product: product, updatedQuantity: product.stockQuantity, imageService: imageService)
        default:
            break
        }
    }

    func handleSelectedChange(selected: ProductSKUScannerResult) {
        onSelection(selected)
    }

    func isSelected(model: ProductSKUScannerResult) -> Bool {
        model == selected
    }
}
