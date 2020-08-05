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

    /// Boolean indicating if there are reviews
    ///
    var isEmpty: Bool {
        return reviewsResultsController.isEmpty
    }

    /// Notifications associated with the reviews. In this case, we don't want to show notifications.
    ///
    var notifications: [Note] {
        return []
    }

    /// Identifiers of the Products mentioned in the reviews.
    /// Guaranteed to be uniqued (does not contain duplicates)
    ///
    var reviewsProductsIDs: [Int64] {
        return reviewsResultsController
            .fetchedObjects
            .map { return $0.productID }
            .uniqued()
    }

    var reviewCount: Int {
        return reviewsResultsController.numberOfObjects
    }


    init(product: Product) {
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
        return NSPredicate(format: "siteID == %lld",
                          ServiceLocator.stores.sessionManager.defaultStoreID ?? Int.min)
    }

    /// Initializes observers for incoming reviews
    ///
    func observeReviews() throws {
        try reviewsResultsController.performFetch()
    }

    func stopForwardingEvents() {
        reviewsResultsController.stopForwardingEvents()
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProductReviewTableViewCell.reuseIdentifier) as? ProductReviewTableViewCell else {
            fatalError()
        }

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

    private func reviewViewModel(at indexPath: IndexPath) -> ReviewViewModel {
        let review = reviewsResultsController.object(at: indexPath)

        return ReviewViewModel(showProductTitle: false, review: review, product: product, notification: nil)
    }
}


// MARK: - Conformance to ReviewsInteractionDelegate & UITableViewDelegate
//
extension ProductReviewsDataSource: ReviewsInteractionDelegate {
    func didSelectItem(at indexPath: IndexPath, in viewController: UIViewController) {
        // no-op: we don't want to catch the selected item in Products
    }

    func presentReviewDetails(for noteID: Int64, in viewController: UIViewController) {
        // no-op: we don't want to present the review details in Products
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


private extension ProductReviewsDataSource {
    enum Settings {
        static let estimatedRowHeight = CGFloat(88)
    }
}
