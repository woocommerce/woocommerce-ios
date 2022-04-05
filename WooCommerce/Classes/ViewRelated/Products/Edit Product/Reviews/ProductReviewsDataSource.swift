import Foundation
import UIKit
import Yosemite


/// Product Reviews implementation of the ReviewsDataSource, dequeues and
/// populates cells to render the Product Review list for a specific Product.
///
final class ProductReviewsDataSource: NSObject, ReviewsDataSource {

    // MARK: - Private properties

    /// Product Reviews
    ///
    private lazy var reviewsResultsController: ResultsController<StorageProductReview> = {
        let storageManager = ServiceLocator.storageManager
        let descriptor = NSSortDescriptor(keyPath: \StorageProductReview.dateCreated, ascending: false)

        return ResultsController<StorageProductReview>(storageManager: storageManager,
                                                       sectionNameKeyPath: "normalizedAgeAsString",
                                                       matching: filterPredicate(),
                                                       sortedBy: [descriptor])
    }()

    /// Keep track of the (Autosizing Cell's) Height. This helps us prevent UI flickers, due to sizing recalculations.
    ///
    private var estimatedRowHeights = [IndexPath: CGFloat]()

    // MARK: - Private properties

    /// Product for which we show the reviews.
    ///
    private let product: Product
    private let siteID: Int64

    /// Boolean indicating if there are reviews
    ///
    var isEmpty: Bool {
        return reviewsResultsController.isEmpty
    }

    /// With this `ResultsController` we retrieve the WordPress.com notifications associated with the product reviews.
    /// Later we can filter them and pass it to the review detail view so it can be marked as read.
    ///
    private lazy var notificationsResultsController: ResultsController<StorageNote> = {
        let storageManager = ServiceLocator.storageManager
        let descriptor = NSSortDescriptor(keyPath: \StorageNote.timestamp, ascending: false)

        return ResultsController<StorageNote>(storageManager: storageManager,
                                              sectionNameKeyPath: "normalizedAgeAsString",
                                              matching: notificationsPredicate,
                                              sortedBy: [descriptor])
    }()

    private lazy var notificationsPredicate: NSPredicate = {
        let notDeletedPredicate = NSPredicate(format: "deleteInProgress == NO")
        let typeReviewPredicate =  NSPredicate(format: "subtype == %@", Note.Subkind.storeReview.rawValue)

        return NSCompoundPredicate(andPredicateWithSubpredicates: [typeReviewPredicate,
                                                                   sitePredicate(),
                                                                   notDeletedPredicate])
    }()

    /// Notifications associated with the reviews.
    /// To be filtered and marked as read in the review detail view if they are linked to the review.
    ///
    var notifications: [Note] {
        return notificationsResultsController.fetchedObjects
    }

    var reviewCount: Int {
        return reviewsResultsController.numberOfObjects
    }

    init(product: Product) {
        self.siteID = product.siteID
        self.product = product
        super.init()
    }

    /// Predicate to filter only Product Reviews that are approved
    ///
    private func filterPredicate() -> NSPredicate {
        let statusPredicate = NSPredicate(format: "statusKey ==[c] %@ AND productID == %lld",
                                          ProductReviewStatus.approved.rawValue,
                                          product.productID)

        return  NSCompoundPredicate(andPredicateWithSubpredicates: [sitePredicate(), statusPredicate])
    }

    /// Predicate to entities that belong to the current store
    ///
    private func sitePredicate() -> NSPredicate {
        NSPredicate(format: "siteID == %lld", siteID)
    }

    /// Initializes observers for incoming reviews
    ///
    func observeReviews() throws {
        try reviewsResultsController.performFetch()
    }

    func startForwardingEvents(to tableView: UITableView) {
        reviewsResultsController.startForwardingEvents(to: tableView)
    }

    func refreshDataObservers() {
        reviewsResultsController.predicate = filterPredicate()
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension ProductReviewsDataSource: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return reviewsResultsController.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reviewsResultsController.sections[section].numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(ProductReviewTableViewCell.self, for: indexPath)

        configure(cell, at: indexPath)

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let rawAge = reviewsResultsController.sections[section].name
        return ReviewAge(rawValue: rawAge)?.description
    }
}


// MARK: - Cell Setup
//
private extension ProductReviewsDataSource {

    /// Initializes the ProductReviewTableViewCell at the specified indexPath
    ///
    func configure(_ cell: ProductReviewTableViewCell, at indexPath: IndexPath) {
        let viewModel = reviewViewModel(at: indexPath)

        cell.configure(with: viewModel)
    }

    func reviewViewModel(at indexPath: IndexPath) -> ReviewViewModel {
        let review = reviewsResultsController.object(at: indexPath)

        return ReviewViewModel(showProductTitle: false, review: review, product: product, notification: nil)
    }

    private func notification(id reviewID: Int64) -> Note? {
        let notifications = notificationsResultsController.fetchedObjects

        return notifications.filter { $0.meta.identifier(forKey: .comment) == Int(reviewID) }.first
    }
}


// MARK: - Conformance to ReviewsInteractionDelegate & UITableViewDelegate
//
extension ProductReviewsDataSource: ReviewsInteractionDelegate {
    func didSelectItem(at indexPath: IndexPath, in viewController: UIViewController) {
        let review = reviewsResultsController.object(at: indexPath)
        let note = notification(id: review.reviewID)

        let detailsViewController = ReviewDetailsViewController(productReview: review,
                                                                product: product,
                                                                notification: note)
        viewController.navigationController?.pushViewController(detailsViewController, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return estimatedRowHeights[indexPath] ?? Settings.estimatedRowHeight
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath, with syncingCoordinator: SyncingCoordinator) {

        let orderIndex = reviewsResultsController.objectIndex(from: indexPath)
        syncingCoordinator.ensureNextPageIsSynchronized(lastVisibleIndex: orderIndex)

        // Preserve the Cell Height
        // Why: Because Autosizing Cells, upon reload, will need to be laid yout yet again. This might cause
        // UI glitches / unwanted animations. By preserving it, *then* the estimated will be extremely close to
        // the actual value. AKA no flicker!
        //
        estimatedRowHeights[indexPath] = cell.frame.height
    }
}


extension ProductReviewsDataSource {
    enum Settings {
        static let estimatedRowHeight = CGFloat(88)
    }
}
