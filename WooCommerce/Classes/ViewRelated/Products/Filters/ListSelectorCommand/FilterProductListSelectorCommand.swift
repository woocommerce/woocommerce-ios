import UIKit
import Yosemite

/// `ListSelectorCommand` for selecting a filter.
final class FilterProductListSelectorCommand: ListSelectorCommand {
    typealias Model = FilterProductListCommand.ProductListFilter
    typealias Cell = SettingTitleAndValueTableViewCell

    /// If there are any active filters, "Filters (#)" is shown in the navigation bar for example.
    /// Otherwise, "Filters" is shown when all filters are cleared.
    var navigationBarTitle: String? {
        let activeFilterCount = numberOfActiveFilters(filters: filters)
        return activeFilterCount > 0 ?
            String.localizedStringWithFormat(Strings.navigationBarTitleFormatWithActiveFilters, activeFilterCount):
            Strings.navigationBarTitleWithoutActiveFilters
    }

    let data: [FilterProductListCommand.ProductListFilter] = [.stockStatus, .productStatus, .productType]

    private(set) var selected: FilterProductListCommand.ProductListFilter?

    /// The source of truth for the latest filter values, set in `FilterProductListCommand` when any filter value changes.
    var filters: FilterProductListCommand.Filters

    private let onFilterSelected: (_ filter: FilterProductListCommand.ProductListFilter, _ viewController: ViewController) -> Void

    /// - Parameters:
    ///   - filters: the filters to be applied initially.
    ///   - onFilterSelected: called when the user taps on a filter row (e.g. "Stock status").
    init(filters: FilterProductListCommand.Filters,
         onFilterSelected: @escaping (_ filter: FilterProductListCommand.ProductListFilter, _ viewController: ViewController) -> Void) {
        self.filters = filters
        self.onFilterSelected = onFilterSelected
    }

    func configureCell(cell: SettingTitleAndValueTableViewCell, model: FilterProductListCommand.ProductListFilter) {
        cell.selectionStyle = .default
        cell.updateUI(title: model.title, value: value(for: model))
    }

    func handleSelectedChange(selected: FilterProductListCommand.ProductListFilter, viewController: ViewController) {
        onFilterSelected(selected, viewController)
    }

    func isSelected(model: FilterProductListCommand.ProductListFilter) -> Bool {
        return model == selected
    }
}

// MARK: - Private helpers
//
private extension FilterProductListSelectorCommand {
    func value(for filter: FilterProductListCommand.ProductListFilter) -> String {
        switch filter {
        case .stockStatus:
            return filters.stockStatus?.description ?? Constant.noFilterValueTitle
        case .productStatus:
            return filters.productStatus?.description ?? Constant.noFilterValueTitle
        case .productType:
            return filters.productType?.description ?? Constant.noFilterValueTitle
        }
    }

    func numberOfActiveFilters(filters: FilterProductListCommand.Filters) -> Int {
        let filterValues: [Any?] = [filters.stockStatus, filters.productStatus, filters.productType]
        return filterValues.filter({ $0 != nil }).count
    }
}

private extension FilterProductListSelectorCommand {
    enum Constant {
        static let noFilterValueTitle = NSLocalizedString("Any", comment: "Title when there is no filter set.")
    }

    enum Strings {
        static let navigationBarTitleWithoutActiveFilters =
            NSLocalizedString("Filters", comment: "Navigation bar title format for filtering a list of products without filters applied.")
        static let navigationBarTitleFormatWithActiveFilters =
            NSLocalizedString("Filters (%ld)", comment: "Navigation bar title format for filtering a list of products with filters applied.")
    }
}

fileprivate extension FilterProductListCommand.ProductListFilter {
    var title: String {
        switch self {
        case .stockStatus:
            return NSLocalizedString("Stock status", comment: "Row title for filtering products by stock status.")
        case .productStatus:
            return NSLocalizedString("Product status", comment: "Row title for filtering products by product status.")
        case .productType:
            return NSLocalizedString("Product type", comment: "Row title for filtering products by product type.")
        }
    }
}
