import Foundation
import Combine
import Yosemite

/// View model for the `ReviewReply` screen.
///
final class ReviewReplyViewModel: ObservableObject {

    /// New reply to send
    ///
    @Published var newReply: String = ""

    /// Defaults to a disabled send button.
    ///
    @Published private(set) var navigationTrailingItem: ReviewReplyNavigationItem = .send(enabled: false)

    /// Tracks if a network request is being performed.
    ///
    private let performingNetworkRequest: CurrentValueSubject<Bool, Never> = .init(false)

    init() {
        bindNavigationTrailingItemPublisher()
    }

    /// Called when the user taps on the Send button.
    ///
    /// Use this method to send the reply and invoke a completion block when finished
    ///
    func sendReply(onCompletion: @escaping (Bool) -> Void) {
        // TODO: Call CommentAction.replyToComment to send the reply to remote
        // Set `performingNetworkRequest` to true while the request is being performed
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
