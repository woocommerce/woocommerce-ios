import Foundation
import Combine
import Yosemite

/// View model for the `ReviewReply` screen.
///
final class ReviewReplyViewModel: ObservableObject {

    private let siteID: Int64

    /// ID for the product review being replied to.
    ///
    private let reviewID: Int64

    /// New reply to send
    ///
    @Published var newReply: String = ""

    /// Defaults to a disabled send button.
    ///
    @Published private(set) var navigationTrailingItem: ReviewReplyNavigationItem = .send(enabled: false)

    /// Tracks if a network request is being performed.
    ///
    private let performingNetworkRequest: CurrentValueSubject<Bool, Never> = .init(false)

    /// Action dispatcher
    ///
    private let stores: StoresManager

    init(siteID: Int64, reviewID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.reviewID = reviewID
        self.stores = stores
        bindNavigationTrailingItemPublisher()
    }

    /// Called when the user taps on the Send button.
    ///
    /// Use this method to send the reply and invoke a completion block when finished
    ///
    func sendReply(onCompletion: @escaping (Bool) -> Void) {
        guard newReply.isNotEmpty else {
            return
        }

        let action = CommentAction.replyToComment(siteID: siteID, commentID: reviewID, content: newReply) { [weak self] result in
            guard let self = self else { return }

            self.performingNetworkRequest.send(false)

            switch result {
            case .success:
                // TODO: Show a success notice, e.g. "Reply sent!"
                onCompletion(true)
            case .failure(let error):
                // TODO: Show an error notice, e.g. "There was an error sending the reply"
                onCompletion(false)
            }
        }

        performingNetworkRequest.send(true)
        stores.dispatch(action)
    }
}

// MARK: Helper Methods
private extension ReviewReplyViewModel {
    /// Calculates what navigation trailing item should be shown depending on our internal state.
    ///
    func bindNavigationTrailingItemPublisher() {
        Publishers.CombineLatest($newReply, performingNetworkRequest)
            .map { newReply, performingNetworkRequest in
                guard !performingNetworkRequest else {
                    return .loading
                }
                return .send(enabled: newReply.isNotEmpty)
            }
            .assign(to: &$navigationTrailingItem)
    }
}

/// Representation of possible navigation bar trailing buttons
///
enum ReviewReplyNavigationItem: Equatable {
    case send(enabled: Bool)
    case loading
}
