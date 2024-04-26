import Foundation
import UIKit
import WordPressUI
import Yosemite
import class AutomatticTracks.CrashLogging

/// The Product Reviews view model used in ProductReviewsViewController
final class ProductReviewsViewModel {
    private let data: ReviewsDataSourceProtocol

    var isEmpty: Bool {
        return data.isEmpty
    }

    var dataSource: UITableViewDataSource {
        return data
    }

    var delegate: ReviewsInteractionDelegate {
        return data
    }

    private let siteID: Int64

    init(siteID: Int64, data: ReviewsDataSourceProtocol) {
        self.siteID = siteID
        self.data = data
    }

    func configureResultsController(tableView: UITableView) {
        data.startForwardingEvents(to: tableView)

        do {
            try data.observeReviews()
        } catch {
            ServiceLocator.crashLogging.logError(error)
        }

        // Reload table because observeReviews() executes performFetch()
        tableView.reloadData()
    }

    func refreshResults() {
        data.refreshDataObservers()
    }

    /// Setup: TableViewCells
    ///
    func configureTableViewCells(tableView: UITableView) {
        tableView.registerNib(for: ProductReviewTableViewCell.self)
    }

    func containsMorePages(_ highestVisibleReview: Int) -> Bool {
        return highestVisibleReview > data.reviewCount
    }
}


// MARK: - Fetching data
extension ProductReviewsViewModel {

    /// Synchronizes the Reviews associated to the current store, for a specific Product ID.
    ///
    func synchronizeReviews(pageNumber: Int,
                            pageSize: Int,
                            productID: Int64,
                            onCompletion: (() -> Void)? = nil) {
        let action = ProductReviewAction.synchronizeProductReviews(siteID: siteID,
                                                                   pageNumber: pageNumber,
                                                                   pageSize: pageSize,
                                                                   products: [productID]) { result in
            switch result {
            case .failure(let error):
                DDLogError("⛔️ Error synchronizing reviews for product ID :\(productID). Error: \(error)")
                ServiceLocator.analytics.track(.productReviewListLoadFailed, withError: error)
            case .success:
                ServiceLocator.analytics.track(.productReviewListLoaded)
            }
            onCompletion?()
        }

        ServiceLocator.stores.dispatch(action)
    }
}

private extension ProductReviewsViewModel {
    enum Settings {
        static let firstPage = 1
        static let pageSize = 25
    }
}

/// Customizes the `ReviewsDataSource` for a product related reviews screen (only the reviews of the passed product)
final class ProductReviewsDataSourceCustomizer: ReviewsDataSourceCustomizing {
    let shouldShowProductTitleOnCells = false
    private let product: Product

    init(product: Product) {
        self.product = product
    }

    func reviewsFilterPredicate(with sitePredicate: NSPredicate) -> NSPredicate {
        let statusPredicate = NSPredicate(format: "statusKey ==[c] %@ OR statusKey ==[c] %@",
                                          ProductReviewStatus.approved.rawValue,
                                          ProductReviewStatus.hold.rawValue)

        let productPredicate = NSPredicate(format: "productID == %lld",
                                          product.productID)

        return  NSCompoundPredicate(andPredicateWithSubpredicates: [sitePredicate, statusPredicate, productPredicate])
    }
}
