import Foundation
import Yosemite
import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics

/// View model for `ReviewsDashboardCard`
///
final class ReviewsDashboardCardViewModel: ObservableObject {
    // Set externally to trigger callback upon hiding the Reviews card
    var onDismiss: (() -> Void)?

    // Available filtering option for the shown reviews
    enum ReviewsFilter {
        // Show all reviews
        case all
        // Show reviews in hold status
        case hold
        // Show reviews in approved status
        case approved
    }

    @Published private(set) var data: [ReviewViewModel] = []
    private var reviewProducts: [Product] {
        return productsResultsController.fetchedObjects
    }
    @Published private(set) var syncingData = false
    @Published private(set) var syncingError: Error?

    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let analytics: Analytics

    public let siteID: Int64
    public let filters: [ReviewsFilter] = [.all, .hold, .approved]

    private let productsResultsController: ResultsController<StorageProduct>

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.stores = stores
        self.storageManager = storageManager
        self.analytics = analytics

        self.productsResultsController = ResultsController<StorageProduct>(storageManager: storageManager,
                                                                           matching: nil,
                                                                           fetchLimit: Constants.numberOfItems,
                                                                           sortedBy: [])
        configureProductReviewsResultsController()
    }

    /// ResultsController for ProductReview
    private lazy var productReviewsResultsController: ResultsController<StorageProductReview> = {
        let sortDescriptor = NSSortDescriptor(keyPath: \StorageProductReview.dateCreated, ascending: false)
        return ResultsController<StorageProductReview>(storageManager: storageManager,
                                                       matching: sitePredicate(),
                                                       fetchLimit: Constants.numberOfItems,
                                                       sortedBy: [sortDescriptor])
    }()

    func dismissReviews() {
        // TODO: add tracking
        onDismiss?()
    }

    @MainActor
    func reloadData() async {
        syncingData = true
        syncingError = nil
        do {
            try await loadReviews()
        } catch {
            syncingError = error
        }
        syncingData = false
    }
}

// MARK: - Storage related
private extension ReviewsDashboardCardViewModel {
    /// Predicate to entities that belong to the current store
    ///
    func sitePredicate() -> NSPredicate {
        return NSPredicate(format: "siteID == %lld", siteID)
    }

    /// Performs initial fetch from storage and updates results.
    ///
    func configureProductReviewsResultsController() {
        productReviewsResultsController.onDidChangeContent = { [weak self] in
            guard let self else { return }
            Task {
                await self.updateReviewsResults()
            }
        }
        productReviewsResultsController.onDidResetContent = { [weak self] in
            guard let self else { return }
            Task {
                await self.updateReviewsResults()
            }
        }

        do {
            try productReviewsResultsController.performFetch()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    func updateProductsResultsControllerPredicate(with productIDs: [Int64]) {
        let predicates = NSCompoundPredicate(andPredicateWithSubpredicates: [sitePredicate(),
                                                                             NSPredicate(format: "productID IN %@", productIDs)])
        productsResultsController.predicate = predicates
    }
}

// MARK: - Private helpers
private extension ReviewsDashboardCardViewModel {
    @MainActor
    func loadReviews() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            stores.dispatch(ProductReviewAction.synchronizeProductReviews(siteID: siteID,
                                                                          pageNumber: 1,
                                                                          pageSize: Constants.numberOfItems) { result in
                switch result {
                case .success:
                    // Ignoring the result from remote as we're using storage as the single source of truth
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
        }
    }

    /// Updates data
    @MainActor
    func updateReviewsResults() async {
        let reviews = productReviewsResultsController.fetchedObjects.prefix(Constants.numberOfItems)
        let productIDs = reviews.map { $0.productID }

        if productIDs.isNotEmpty {
            updateProductsResultsControllerPredicate(with: productIDs)
            do {
                try await fetchProducts(for: productIDs)
            } catch {
                ServiceLocator.crashLogging.logError(error)
            }
        }

        data = reviews
            .map { review in
                let product = reviewProducts.first { $0.productID == review.productID }
                // TODO: also fetch notification
                return ReviewViewModel(review: review, product: product, notification: nil)
            }
    }

    /// Get products from storage if available, if not then fetch remotely.
    ///
    @MainActor
    private func fetchProducts(for productIDs: [Int64]) async throws {
        try productsResultsController.performFetch()

        // Check if all productIDs are available in storage
        let allProductsAvailable = productIDs.allSatisfy { productID in
            reviewProducts.contains { $0.productID == productID }
        }

        if !allProductsAvailable {
            await loadReviewProducts(for: productIDs)
        }
    }

    @MainActor
    func loadReviewProducts(for reviewProductIDs: [Int64]) async {
        syncingData = true
        syncingError = nil

        do {
            try await retrieveProducts(for: reviewProductIDs)
        } catch {
            syncingError = error
        }
        syncingData = false
    }

    @MainActor
    func retrieveProducts(for reviewProductIDs: [Int64]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            stores.dispatch(ProductAction.retrieveProducts(siteID: siteID,
                                                           productIDs: reviewProductIDs
                                                          ) { result in
                switch result {
                case .success:
                    // Ignoring the result from remote as we're using storage as the single source of truth
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            })
        }
    }
}

private extension ReviewsDashboardCardViewModel {
    enum Constants {
         static let numberOfItems = 3
     }
}

extension ReviewsDashboardCardViewModel.ReviewsFilter {
    var title: String {
        switch self {
        case .all:
            return Localization.filterAll
        case .hold:
            return Localization.filterHold
        case .approved:
            return Localization.filterApproved
        }
    }

    enum Localization {
        static let filterAll = NSLocalizedString(
            "reviewsDashboardCardViewModel.filterAll",
            value: "All",
            comment: "Menu item to dismiss the Reviews card on the Dashboard screen"
        )
        static let filterHold = NSLocalizedString(
            "reviewsDashboardCardViewModel.filterHold",
            value: "Hold",
            comment: "Status label on the Reviews card's filter area."
        )
        static let filterApproved = NSLocalizedString(
            "reviewsDashboardCardViewModel.filterApproved",
            value: "Approved",
            comment: "Button to navigate to Reviews list screen."
        )
    }
}
