import Foundation
import UIKit
import Yosemite


final class ReviewsDataSource: NSObject {
    lazy var reviewsResultsController: ResultsController<StorageProductReview> = {
        let storageManager = ServiceLocator.storageManager
        let descriptor = NSSortDescriptor(keyPath: \StorageProductReview.dateCreated, ascending: false)

        return ResultsController<StorageProductReview>(storageManager: storageManager,
                                                       sectionNameKeyPath: "normalizedAgeAsString",
                                                       matching: self.filterPredicate,
                                                       sortedBy: [descriptor])
    }()

    private lazy var productsResultsController: ResultsController<StorageProduct> = {
        let storageManager = ServiceLocator.storageManager
        let descriptor = NSSortDescriptor(keyPath: \StorageProduct.productID, ascending: true)

        return ResultsController<StorageProduct>(storageManager: storageManager,
                                                       matching: sitePredicate,
                                                       sortedBy: [descriptor])
    }()

    private lazy var filterPredicate: NSPredicate = {
        let statusPredicate = NSPredicate(format: "statusKey ==[c] %@ OR statusKey ==[c] %@",
                                          ProductReviewStatus.approved.rawValue,
                                          ProductReviewStatus.hold.rawValue)

        return  NSCompoundPredicate(andPredicateWithSubpredicates: [sitePredicate, statusPredicate])
    }()

    private lazy var sitePredicate: NSPredicate = {
        return NSPredicate(format: "siteID == %lld",
                          ServiceLocator.stores.sessionManager.defaultStoreID ?? Int.min)
    }()

    /// Keep track of the (Autosizing Cell's) Height. This helps us prevent UI flickers, due to sizing recalculations.
    ///
    private var estimatedRowHeights = [IndexPath: CGFloat]()

    override init() {
        super.init()
        observeResults()
    }

    private func observeResults() {
        try? productsResultsController.performFetch()
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension ReviewsDataSource: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return reviewsResultsController.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reviewsResultsController.sections[section].numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NoteTableViewCell.reuseIdentifier) as? NoteTableViewCell else {
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
private extension ReviewsDataSource {

    /// Initializes the Notifications Cell at the specified indexPath
    ///
    func configure(_ cell: NoteTableViewCell, at indexPath: IndexPath) {
        let review = reviewsResultsController.object(at: indexPath)
        let reviewProduct = product(id: review.productID)

        let viewModel = ReviewViewModel(review: review, product: reviewProduct)
        cell.configure(with: viewModel)
    }

    private func product(id productID: Int) -> Product? {
        let products = productsResultsController.fetchedObjects

        return products.filter { $0.productID == productID }.first
    }
}


extension ReviewsDataSource: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return estimatedRowHeights[indexPath] ?? Settings.estimatedRowHeight
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let review = reviewsResultsController.object(at: indexPath)
        presentDetails(for: review)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        // Preserve the Cell Height
        // Why: Because Autosizing Cells, upon reload, will need to be laid yout yet again. This might cause
        // UI glitches / unwanted animations. By preserving it, *then* the estimated will be extremely close to
        // the actual value. AKA no flicker!
        //
        estimatedRowHeights[indexPath] = cell.frame.height
    }
}

// MARK: - Public Methods
//
private extension ReviewsDataSource {

    /// Presents the Details for a given Note Instance: Either NotificationDetails, or OrderDetails, depending on the
    /// Notification's Kind.
    ///
    func presentDetails(for review: ProductReview) {
        print("==== presenting detils for review")

        //        let detailsViewController = NotificationDetailsViewController(note: note)
        //        navigationController?.pushViewController(detailsViewController, animated: true)
    }
}


private extension ReviewsDataSource {
    enum Settings {
        static let estimatedRowHeight = CGFloat(88)
    }
}
