import Foundation
import Yosemite

/// Implementation of `SearchUICommand` for Coupon search.
final class CouponSearchUICommand: SearchUICommand {

    typealias Model = Coupon
    typealias CellViewModel = TitleAndSubtitleAndStatusTableViewCell.ViewModel
    typealias ResultsControllerModel = StorageCoupon

    let searchBarPlaceholder = Localization.searchBarPlaceholder

    let searchBarAccessibilityIdentifier = "coupon-search-screen-search-field"

    let cancelButtonAccessibilityIdentifier = "coupon-search-screen-cancel-button"

    func createResultsController() -> ResultsController<StorageCoupon> {
        let storageManager = ServiceLocator.storageManager
        let descriptor = NSSortDescriptor(keyPath: \StorageCoupon.dateCreated, ascending: false)
        return ResultsController<StorageCoupon>(storageManager: storageManager, sortedBy: [descriptor])
    }

    func createStarterViewController() -> UIViewController? {
        nil
    }

    func createCellViewModel(model: Coupon) -> TitleAndSubtitleAndStatusTableViewCell.ViewModel {
        CellViewModel(title: model.code,
                      subtitle: model.discountType.localizedName, // to be updated after UI is finalized
                      accessibilityLabel: model.description.isEmpty ? model.description : model.code,
                      status: model.expiryStatus().localizedName,
                      statusBackgroundColor: model.expiryStatus().statusBackgroundColor)
    }

    func synchronizeModels(siteID: Int64, keyword: String, pageNumber: Int, pageSize: Int, onCompletion: ((Bool) -> Void)?) {
        let action = CouponAction.searchCoupons(siteID: siteID, keyword: keyword, pageNumber: pageNumber, pageSize: pageSize) { result in

            if case .failure(let error) = result {
                DDLogError("☠️ Coupon Search Failure! \(error)")
            }

            onCompletion?(result.isSuccess)
        }

        ServiceLocator.stores.dispatch(action)
        // TODO: add analytics
    }

    func didSelectSearchResult(model: Coupon, from viewController: UIViewController, reloadData: () -> Void, updateActionButton: () -> Void) {
        // TODO: Show coupon details screen
    }

    func configureEmptyStateViewControllerBeforeDisplay(viewController: EmptyStateViewController,
                                                        searchKeyword: String) {
        let boldSearchKeyword = NSAttributedString(string: searchKeyword,
                                                   attributes: [.font: EmptyStateViewController.Config.messageFont.bold])

        let format = Localization.emptyResultMessage
        let message = NSMutableAttributedString(string: format)
        message.replaceFirstOccurrence(of: "%@", with: boldSearchKeyword)

        viewController.configure(.simple(message: message, image: .emptySearchResultsImage))
    }
}

// MARK: - Subtypes
//
private extension CouponSearchUICommand {
    enum Localization {
        static let searchBarPlaceholder = NSLocalizedString("Search all coupons", comment: "Coupons Search Placeholder")
        static let emptyResultMessage = NSLocalizedString("We're sorry, we couldn't find results for “%@”",
                                                          comment: "Message for empty Coupons search results. The %@ is a " +
                                                          "placeholder for the text entered by the user.")
    }
}
