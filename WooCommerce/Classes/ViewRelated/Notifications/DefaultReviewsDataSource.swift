import Foundation
import UIKit
import Yosemite


/// Default implementation of the ReviewsDataSource, dequeues and
/// populates cells to render the Product Review list
///
final class DefaultReviewsDataSource: NSObject, ReviewsDataSource {

    // MARK: - Private properties

    /// Product Reviews
    ///
    private lazy var reviewsResultsController: ResultsController<StorageProductReview> = {
        let storageManager = ServiceLocator.storageManager
        let descriptor = NSSortDescriptor(keyPath: \StorageProductReview.dateCreated, ascending: false)

        return ResultsController<StorageProductReview>(storageManager: storageManager,
                                                       sectionNameKeyPath: "normalizedAgeAsString",
                                                       matching: self.filterPredicate,
                                                       sortedBy: [descriptor])
    }()

    /// Products
    ///
    private lazy var productsResultsController: ResultsController<StorageProduct> = {
        let storageManager = ServiceLocator.storageManager
        let descriptor = NSSortDescriptor(keyPath: \StorageProduct.productID, ascending: true)

        return ResultsController<StorageProduct>(storageManager: storageManager,
                                                       matching: sitePredicate,
                                                       sortedBy: [descriptor])
    }()

    /// Predicate to filter only Product Reviews that are either approved or on hold
    ///
    private lazy var filterPredicate: NSPredicate = {
        let statusPredicate = NSPredicate(format: "statusKey ==[c] %@ OR statusKey ==[c] %@",
                                          ProductReviewStatus.approved.rawValue,
                                          ProductReviewStatus.hold.rawValue)

        return  NSCompoundPredicate(andPredicateWithSubpredicates: [sitePredicate, statusPredicate])
    }()

    /// Predicate to entities that belong to the current store
    ///
    private lazy var sitePredicate: NSPredicate = {
        return NSPredicate(format: "siteID == %lld",
                          ServiceLocator.stores.sessionManager.defaultStoreID ?? Int.min)
    }()

    /// Keep track of the (Autosizing Cell's) Height. This helps us prevent UI flickers, due to sizing recalculations.
    ///
    private var estimatedRowHeights = [IndexPath: CGFloat]()

    // MARK: - Private properties

    /// Boolean indicating if there are reviews
    ///
    var isEmpty: Bool {
        return reviewsResultsController.isEmpty
    }

    /// Identifiers of the Products mentioned in the reviews.
    /// Guaranteed to be uniqued (does not contain duplicates)
    ///
    var reviewsProductsIDs: [Int] {
        return reviewsResultsController
            .fetchedObjects
            .map { return $0.productID }
            .uniqued()
    }


    override init() {
        super.init()
        observeResults()
    }

    /// Initialise obervers
    ///
    private func observeResults() {
        try? productsResultsController.performFetch()
    }

    /// Initializes observers for incoming reviews
    ///
    func observeReviews() throws {
        try? reviewsResultsController.performFetch()
    }

    func stopForwardingEvents() {
        reviewsResultsController.stopForwardingEvents()
    }

    func startForwardingEvents(to tableView: UITableView) {
        reviewsResultsController.startForwardingEvents(to: tableView)
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension DefaultReviewsDataSource: UITableViewDataSource {

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
private extension DefaultReviewsDataSource {

    /// Initializes the Notifications Cell at the specified indexPath
    ///
    func configure(_ cell: ProductReviewTableViewCell, at indexPath: IndexPath) {
        let viewModel = reviewViewModel(at: indexPath)

        cell.configure(with: viewModel)
    }

    private func reviewViewModel(at indexPath: IndexPath) -> ReviewViewModel {
        let review = reviewsResultsController.object(at: indexPath)
        let reviewProduct = product(id: review.productID)

        return ReviewViewModel(review: review, product: reviewProduct)
    }

    private func product(id productID: Int) -> Product? {
        let products = productsResultsController.fetchedObjects

        return products.filter { $0.productID == productID }.first
    }
}


// MARK: - Conformance to ReviewsInteractionDelegate & UITableViewDelegate
//
extension DefaultReviewsDataSource: ReviewsInteractionDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return estimatedRowHeights[indexPath] ?? Settings.estimatedRowHeight
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        // Preserve the Cell Height
        // Why: Because Autosizing Cells, upon reload, will need to be laid yout yet again. This might cause
        // UI glitches / unwanted animations. By preserving it, *then* the estimated will be extremely close to
        // the actual value. AKA no flicker!
        //
        estimatedRowHeights[indexPath] = cell.frame.height
    }

    func didSelectItem(at indexPath: IndexPath, in viewController: UIViewController) {
        let review = reviewsResultsController.object(at: indexPath)
        let reviewedProduct = product(id: review.productID)

        let detailsViewController = ReviewDetailsViewController(productReview: review, product: reviewedProduct)
        viewController.navigationController?.pushViewController(detailsViewController, animated: true)
    }
}


private extension DefaultReviewsDataSource {
    enum Settings {
        static let estimatedRowHeight = CGFloat(88)
    }
}
