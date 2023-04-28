import Foundation

private enum ProductTrackingSource: String {
    case popular
    case recent
    case alphabetical
    case search
}

final class ProductSelectorViewModelTracker {
    private let analytics: Analytics
    private var productIDTrackingSources: [Int64: ProductTrackingSource] = [:]
    weak var viewModel: ProductSelectorViewModel?
    private let trackProductsSource: Bool

    init(analytics: Analytics, trackProductsSource: Bool) {
        self.analytics = analytics
        self.trackProductsSource = trackProductsSource
    }

    func trackConfirmButtonTapped(with productsCount: Int) {
        let trackingSources = Array(productIDTrackingSources.values.map { $0.rawValue })
        let filtersAreActive = (viewModel?.filterListViewModel.criteria.numberOfActiveFilters ?? 0 > 0)
        analytics.track(event: WooAnalyticsEvent.Orders.orderCreationProductSelectorConfirmButtonTapped(productCount: productsCount,
                                                                                                        sources: trackingSources,
                                                                                                        isFilterActive: filtersAreActive))
    }

    func updateTrackingSourceAfterSelectionStateChangedForProduct(with productID: Int64) {
        guard productIDTrackingSources[productID] == nil else {
            productIDTrackingSources.removeValue(forKey: productID)

            return
        }

        if let trackingSource = retrieveTrackingSource(for: productID) {
            productIDTrackingSources[productID] = trackingSource
        }
    }

    func updateTrackingSourceAfterSelectionStateChangedForProduct(with productID: Int64, selectedVariationIDs: [Int64]) {
        guard selectedVariationIDs.isNotEmpty else {
            productIDTrackingSources.removeValue(forKey: productID)

            return
        }

        productIDTrackingSources[productID] =  retrieveTrackingSource(for: productID)
    }
}

private extension ProductSelectorViewModelTracker {
    func retrieveTrackingSource(for productID: Int64) -> ProductTrackingSource? {
        guard trackProductsSource,
              let viewModel = viewModel else {
            return nil
        }

        guard viewModel.searchTerm.isEmpty else {
            return .search
        }

        guard !sectionContainsProductID(sectionType: .mostPopular, productID: productID) else {
            return .popular
        }

        guard !sectionContainsProductID(sectionType: .lastSold, productID: productID) else {
            return .recent
        }

        return .alphabetical
    }

    func sectionContainsProductID(sectionType: ProductSelectorSectionType, productID: Int64) -> Bool {
        guard let viewModel = viewModel else {
            return false
        }

        let section = viewModel.sections.first(where: { $0.type == sectionType })

        return section?.products.first(where: { $0.productID == productID}) != nil
    }
}
