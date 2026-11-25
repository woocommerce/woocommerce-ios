import Foundation
import Yosemite

@MainActor
final class NotificationOpenCoordinator {
    private let stores: StoresManager
    private let noticePresenter: NoticePresenter
    private let beginNavigation: () -> (() -> Bool)?
    private let showDetails: (PushNotification) -> Void
    private let showReview: (ProductReviewFromNoteParcel) -> Void

    init(stores: StoresManager,
         noticePresenter: NoticePresenter,
         beginNavigation: @escaping () -> (() -> Bool)?,
         showDetails: @escaping (PushNotification) -> Void,
         showReview: @escaping (ProductReviewFromNoteParcel) -> Void) {
        self.stores = stores
        self.noticePresenter = noticePresenter
        self.beginNavigation = beginNavigation
        self.showDetails = showDetails
        self.showReview = showReview
    }

    func open(_ notification: PushNotification) {
        guard let isCurrent = beginNavigation() else { return }
        guard notification.kind == .comment else {
            showDetails(notification)
            return
        }

        let completion: (Result<ProductReviewFromNoteParcel, Error>) -> Void = { [weak self] result in
            guard let self, isCurrent() else { return }
            switch result {
            case .failure:
                noticePresenter.enqueue(notice: Notice(title: Localization.failedToRetrieveReviewNotificationDetails))
            case .success(let review):
                showReview(review)
            }
        }

        if let noteID = notification.noteID {
            stores.dispatch(ProductReviewAction.retrieveProductReviewFromNote(noteID: Int64(noteID), onCompletion: completion))
        } else if let reviewID = notification.meta?.identifier(forKey: .comment) {
            stores.dispatch(ProductReviewAction.retrieveProductReviewAndProduct(
                siteID: notification.resolvedSiteID(stores: stores), reviewID: Int64(reviewID), onCompletion: completion))
        }
    }

    enum Localization {
        static let failedToRetrieveReviewNotificationDetails =
            NSLocalizedString("Failed to retrieve the review notification details.",
                              comment: "An error message shown when failing to retrieve information to present a view for a review push notification.")
    }
}
