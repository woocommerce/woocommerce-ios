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
    private var notifications: [Note] {
        return notificationsResultsController.fetchedObjects
    }
    @Published private(set) var syncingData = false
    @Published private(set) var syncingError: Error?
    @Published private(set) var shouldShowAllReviewsButton = false

    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let analytics: Analytics

    public let siteID: Int64
    public let filters: [ReviewsFilter] = [.all, .hold, .approved]
    @Published private(set) var currentFilter: ReviewsFilter = .all

    private let productsResultsController: ResultsController<StorageProduct>
    private let notificationsResultsController: ResultsController<StorageNote>

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

        self.notificationsResultsController = ResultsController<StorageNote>(storageManager: storageManager,
                                                                           sectionNameKeyPath: "normalizedAgeAsString",
                                                                           matching: nil,
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

    private lazy var notificationsPredicate: NSPredicate = {
        let notDeletedPredicate = NSPredicate(format: "deleteInProgress == NO")
        let typeReviewPredicate = NSPredicate(format: "subtype == %@", Note.Subkind.storeReview.rawValue)

        return NSCompoundPredicate(andPredicateWithSubpredicates: [typeReviewPredicate,
                                                                   sitePredicate(),
                                                                   notDeletedPredicate])
    }()

    func dismissReviews() {
        analytics.track(event: .DynamicDashboard.hideCardTapped(type: .reviews))
        onDismiss?()
    }

    @MainActor
    func reloadData() async {
        syncingData = true
        syncingError = nil
        do {
            // Populate review data locally first if available, so that the View can start showing
            // partial review info without product name or read state.
            populateData()

            try await loadReviews(filter: currentFilter)
            syncingData = false
        } catch {
            syncingError = error
        }
    }

    @MainActor
    func filterReviews(by filter: ReviewsFilter) async {
        currentFilter = filter
        await reloadData()
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
    /// Populates data from the local storage for the three main data (reviews, products, notifications).
    ///
    func populateData() {
        let localReviews = productReviewsResultsController.fetchedObjects.prefix(Constants.numberOfItems)

        // We can start showing partial review content as long as there are reviews found in storage.
        // This might be unintuitive because on the view this remove the shimmer even if remote fetch
        // is not yet done, but it's a way to show partial content as soon as possible.
        if localReviews.isEmpty == false {
            syncingData = false
        }

        data = localReviews.map { review in
                let product = reviewProducts.first { $0.productID == review.productID }
                let notification = notifications.first { notification in
                    if let notificationReviewID = notification.meta.identifier(forKey: .comment) {
                        return notificationReviewID == review.reviewID
                    }
                    return false
                }
                return ReviewViewModel(
                    showProductTitle: product != nil,
                    review: review,
                    product: product,
                    notification: notification
                )
            }
    }

    @MainActor
    func loadReviews(filter: ReviewsFilter? = nil) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            stores.dispatch(ProductReviewAction.synchronizeProductReviews(siteID: siteID,
                                                                          pageNumber: 1,
                                                                          pageSize: Constants.numberOfItems,
                                                                          status: currentFilter.productReviewStatus
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

    /// Updates data
    @MainActor
    func updateReviewsResults() async {
        let reviews = productReviewsResultsController.fetchedObjects.prefix(Constants.numberOfItems)
        let productIDs = reviews.map { $0.productID }

        if productIDs.isNotEmpty {
            // Populate data to show partial review content first before fetching more data.
            populateData()

            // As long as the app is able to fetch one review once, then the button should always appear.
            // Later on, when filtering by hold or pending status, the reviews result might become empty.
            // In that case, the app should keep showing the button to allow the user to see all non-filtered reviews.
            shouldShowAllReviewsButton = true

            updateProductsResultsControllerPredicate(with: productIDs)
            do {
                try await fetchProducts(for: productIDs)

                if stores.isAuthenticatedWithoutWPCom == false {
                    notificationsResultsController.predicate = notificationsPredicate
                    try await fetchNotifications()
                }

                // Update data again once products and notifications are fetched from remote
                populateData()
            } catch {
                ServiceLocator.crashLogging.logError(error)
            }
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

    /// Get notifications from storage if available, if not then fetch remotely.
    ///
    @MainActor
    private func fetchNotifications() async throws {
        try notificationsResultsController.performFetch()
        if notifications.isEmpty {
            try await synchronizeNotifications()
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

    @MainActor
    func synchronizeNotifications() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            stores.dispatch(NotificationAction.synchronizeNotifications { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
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

    var productReviewStatus: ProductReviewStatus? {
        switch self {
        case .all:
            return nil // There is no "all" case inside ProductReviewStatus. To fetch everything, this needs to be nil.
        case .approved:
            return .approved
        case .hold:
            return .hold
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
