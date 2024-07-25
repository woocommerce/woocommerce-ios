import Foundation
import Yosemite
import protocol Storage.StorageManagerType
import protocol WooFoundation.Analytics

/// View model for `ReviewsDashboardCard`
///
@MainActor
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

    /// View models for placeholder rows.
    static let placeholderData: [ReviewViewModel] = [Int64](0..<3).map { index in
        // The content does not matter because the text in placeholder rows is redacted.
        ReviewViewModel(showProductTitle: true,
                        review: ProductReview(siteID: 1,
                                              reviewID: index,
                                              productID: 1,
                                              dateCreated: Date(),
                                              statusKey: "",
                                              reviewer: "########",
                                              reviewerEmail: "##############################",
                                              reviewerAvatarURL: nil,
                                              review: "######## ######## ######## ################",
                                              rating: 5,
                                              verified: true),
                        product: nil,
                        notification: nil)
    }

    private var reviews: [ProductReview] {
        return productReviewsResultsController.fetchedObjects
    }
    private var reviewProducts: [Product] {
        return productsResultsController.fetchedObjects
    }
    private var notifications: [Note] {
        return notificationsResultsController.fetchedObjects
    }
    @Published private(set) var syncingError: Error?
    @Published private(set) var syncingData: Bool = false

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
                                                                             matching: nil,
                                                                             sortedBy: [])

        configureResultsController()
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
        analytics.track(event: .DynamicDashboard.cardLoadingStarted(type: .reviews))
        syncingData = true
        syncingError = nil
        do {
            try await synchronizeReviews(filter: currentFilter)
            analytics.track(event: .DynamicDashboard.cardLoadingCompleted(type: .reviews))
        } catch {
            syncingError = error
            DDLogError("⛔️ Dashboard (Reviews) — Error synchronizing reviews: \(error)")
            analytics.track(event: .DynamicDashboard.cardLoadingFailed(type: .reviews, error: error))
        }
        syncingData = false
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

    func configureResultsController() {
        configureProductReviewsResultsController()
        configureProductsResultsController()
        configureNotificationsResultsController()
    }

    func configureProductReviewsResultsController() {
        productReviewsResultsController.onDidChangeContent = { [weak self] in
            guard let self else { return }
            self.updateData()
        }
        productReviewsResultsController.onDidResetContent = { [weak self] in
            guard let self else { return }
            self.updateData()
        }

        do {
            try productReviewsResultsController.performFetch()
            updateData()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    func configureProductsResultsController() {
        productsResultsController.onDidChangeContent = { [weak self] in
            guard let self else { return }
            self.updateData()
        }
        productsResultsController.onDidResetContent = { [weak self] in
            guard let self else { return }
            self.updateData()
        }

        /// Note: Intentionally not doing performFetch() here, as it has to wait for available
        /// productIDs from productReviewsResultsController() for the results to be correct.
    }

    func configureNotificationsResultsController() {
        notificationsResultsController.predicate = notificationsPredicate

        notificationsResultsController.onDidChangeContent = { [weak self] in
            guard let self else { return }
            self.updateData()
        }
        notificationsResultsController.onDidResetContent = { [weak self] in
            guard let self else { return }
            self.updateData()
        }

        do {
            try notificationsResultsController.performFetch()
            updateData()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }
}

// MARK: - Private helpers
private extension ReviewsDashboardCardViewModel {
    /// Populates data from the local storage for the three main data (reviews, products, notifications).
    ///
    func updateData() {
        var filteredLocalReviews: [ProductReview] = []
        if currentFilter != .all {
            filteredLocalReviews = reviews.filter { $0.status == currentFilter.productReviewStatus }
        } else {
            filteredLocalReviews = reviews
        }

        // Ensure to only get the first three items.
        let localReviews = Array(filteredLocalReviews.prefix(Constants.numberOfItems))

        updateDataWithReviews(localReviews)
    }

    func updateDataWithReviews(_ reviews: [ProductReview]) {
        data = reviews.map { review in

            // Depending on the sync progress, `product` and `notification` might still be nil.
            // This is acceptable and the app is able to display partial review content.
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
    func synchronizeReviews(filter: ReviewsFilter) async throws {
        let fetchedReviews = try await synchronizeProductReviews(filter: filter)
        updateDataWithReviews(fetchedReviews)

        let productIDs = fetchedReviews.map { $0.productID }

        if productIDs.isNotEmpty {
            updateProductsResultsController(for: productIDs)

            // Get product names and, optionally, read status from notifications.
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { [weak self] in
                    try await self?.retrieveProducts(for: productIDs)
                }
                if stores.isAuthenticatedWithoutWPCom == false {
                    group.addTask { [weak self] in
                        try await self?.synchronizeNotifications()
                    }
                }
                // rethrow any failure.
                for try await _ in group {
                    // no-op if result doesn't throw any error
                }
            }
        }
    }

    /// update predicate and manually fetch so that new predicate applies.
    ///
    func updateProductsResultsController(for productIDs: [Int64]) {
        productsResultsController.predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [sitePredicate(),
                                            NSPredicate(format: "productID IN %@", productIDs)])
        do {
            try productsResultsController.performFetch()
        }
        catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }
}

// MARK: Remote
private extension ReviewsDashboardCardViewModel {
    @MainActor
    func synchronizeProductReviews (filter: ReviewsFilter? = nil) async throws -> [ProductReview] {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(ProductReviewAction.synchronizeProductReviews(siteID: siteID,
                                                                          pageNumber: 1,
                                                                          pageSize: Constants.numberOfItems,
                                                                          status: currentFilter.productReviewStatus
                                                                         ) { result in
                continuation.resume(with: result)
            })
        }
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
