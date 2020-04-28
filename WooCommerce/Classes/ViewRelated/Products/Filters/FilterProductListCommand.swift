import UIKit
import Yosemite

/// `FilterListCommand` for filtering a list of products.
final class FilterProductListCommand: FilterListCommand {
    /// Aggregates the filter values that can be updated in the Filter Products UI.
    struct Filters {
        let stockStatus: ProductStockStatus?
        let productStatus: ProductStatus?
        let productType: ProductType?
    }

    typealias ListSelectorCommand = FilterProductListSelectorCommand

    let filterActionTitle = NSLocalizedString("Show Products", comment: "Button title for applying filters to a list of products.")

    /// The Clear All CTA is only visible when at least one filter is applied.
    var isClearAllActionVisible: Bool {
        return hasAppliedAnyFilters(filters: filterListSelectorCommand.filters)
    }

    var shouldReloadUIObservable: Observable<Void> {
        shouldReloadUISubject
    }

    private let shouldReloadUISubject: PublishSubject<Void> = PublishSubject<Void>()

    /// Used to configure the list of filters, with a callback when the user taps on a filter row.
    private(set) lazy var filterListSelectorCommand: ListSelectorCommand = {
        FilterProductListSelectorCommand(filters: originalFilters) { [weak self] filter, viewController in
            guard let self = self else {
                return
            }
            self.onFilterSelected(filter, viewController: viewController)
        }
    }()

    /// Used to initialize `filterListSelectorCommand` and also compare for outstanding changes on the filters for the discard changes action sheet.
    private let originalFilters: Filters

    /// Used to dismiss the Filter Products UI.
    private let sourceViewController: UIViewController

    typealias FilterCompletion = (_ filters: Filters) -> Void
    private let onFilterCompletion: FilterCompletion

    /// - Parameters:
    ///   - sourceViewController: the view controller that presents the Filter Products UI, used to dismiss the screen upon user actions.
    ///   - filters: the filters to be applied initially.
    ///   - onFilterCompletion: called when the user taps the Filter CTA to apply the latest filters to the product list.
    init(sourceViewController: UIViewController, filters: Filters, onFilterCompletion: @escaping FilterCompletion) {
        self.sourceViewController = sourceViewController
        self.originalFilters = filters
        self.onFilterCompletion = onFilterCompletion
    }

    func onFilterSelected(_ filter: ProductListFilter, viewController: ListSelectorCommand.ViewController) {
        // TODO-2037: navigate to the filter option list selector
    }

    func onFilterActionTapped() {
        sourceViewController.dismiss(animated: true) { [weak self] in
            guard let self = self else {
                return
            }
            let filters = self.filterListSelectorCommand.filters
            self.onFilterCompletion(filters)
        }
    }

    func onDismissActionTapped() {
        sourceViewController.dismiss(animated: true, completion: nil)
    }

    func onClearAllActionTapped() {
        onFiltersUpdate(filters: Filters(stockStatus: nil, productStatus: nil, productType: nil))
    }
}

private extension FilterProductListCommand {
    func onFiltersUpdate(filters: Filters) {
        guard filters != filterListSelectorCommand.filters else {
            return
        }

        filterListSelectorCommand.filters = filters

        shouldReloadUISubject.send(())
    }

    func hasAppliedAnyFilters(filters: Filters) -> Bool {
        return filters.stockStatus != nil || filters.productStatus != nil || filters.productType != nil
    }
}

extension FilterProductListCommand {
    /// Rows listed in the order they appear on screen
    ///
    enum ProductListFilter {
        case stockStatus
        case productStatus
        case productType
    }
}

extension FilterProductListCommand.Filters: Equatable {
    static func == (lhs: FilterProductListCommand.Filters, rhs: FilterProductListCommand.Filters) -> Bool {
        return lhs.stockStatus == rhs.stockStatus &&
        lhs.productStatus == rhs.productStatus &&
        lhs.productType == rhs.productType
    }
}
