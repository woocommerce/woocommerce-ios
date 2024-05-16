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
    @Published private(set) var syncingData = false
    @Published private(set) var syncingError: Error?

    private let stores: StoresManager
    private let storageManager: StorageManagerType
    private let analytics: Analytics

    public let siteID: Int64
    public let filters: [ReviewsFilter] = [.all, .hold, .approved]

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.stores = stores
        self.storageManager = storageManager
        self.analytics = analytics

        configureResultsController()
    }

    /// Reviews ResultsController
    private lazy var resultsController: ResultsController<StorageProductReview> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let sortDescriptor = NSSortDescriptor(keyPath: \StorageProductReview.dateCreated, ascending: false)
        let resultsController = ResultsController<StorageProductReview>(storageManager: storageManager,
                                                                        matching: predicate,
                                                                        fetchLimit: Constants.numberOfItems,
                                                                        sortedBy: [sortDescriptor])
        return resultsController
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
            // Ignoring the result from remote as we're using storage as the single source of truth
            _ = try await loadReviews()
        } catch {
            syncingError = error
        }
        syncingData = false
    }
}

// MARK: - Private helpers
private extension ReviewsDashboardCardViewModel {
    @MainActor
    func loadReviews() async throws -> [ProductReview] {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(ProductReviewAction.synchronizeProductReviews(siteID: siteID,
                                                                          pageNumber: 1,
                                                                          pageSize: Constants.numberOfItems) { result in
                continuation.resume(with: result)
            })
        }
    }


    /// Performs initial fetch from storage and updates results.
    func configureResultsController() {
        resultsController.onDidChangeContent = { [weak self] in
            self?.updateResults()
        }
        resultsController.onDidResetContent = { [weak self] in
            self?.updateResults()
        }

        do {
            try resultsController.performFetch()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }
    }

    /// Updates data
    func updateResults() {
        data = resultsController.fetchedObjects
            .map { ReviewViewModel(review: $0, product: nil, notification: nil) } // TODO: also fetch product and notification
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
