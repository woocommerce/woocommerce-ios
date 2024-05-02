import Foundation
import StoreKit

final class InAppFeedbackCardViewModel: ObservableObject {
    enum Feedback {
        case liked
        case didntLike
    }

    private let analytics: Analytics

    /// Closure invoked after the user has chosen what kind feedback to give.
    var onFeedbackGiven: ((Feedback) -> Void)?

    private let storeReviewControllerType: SKStoreReviewControllerProtocol.Type

    @Published var presentSurvey = false

    init(storeReviewControllerType: SKStoreReviewControllerProtocol.Type = SKStoreReviewController.self,
         analytics: Analytics = ServiceLocator.analytics) {
        self.storeReviewControllerType = storeReviewControllerType
        self.analytics = analytics
    }

    func didTapCouldBeBetter() {
        analytics.track(event: .appFeedbackPrompt(action: .didntLike))
        onFeedbackGiven?(.didntLike)
    }

    func didTapILikeIt() {
        analytics.track(event: .appFeedbackPrompt(action: .liked))
        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive}) as? UIWindowScene {
            self.storeReviewControllerType.requestReview(in: windowScene)
        }
        onFeedbackGiven?(.liked)
    }
}
