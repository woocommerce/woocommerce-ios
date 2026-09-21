import Foundation
import StoreKit
import protocol WooFoundation.Analytics

/// Defines methods for presenting the in-app App Store review form.
///
@MainActor
protocol AppStoreReviewRequesting {
    /// Displays the in-app App Store review alert.
    ///
    static func requestReview(in windowScene: UIWindowScene)
}

enum AppStoreReviewRequester: AppStoreReviewRequesting {
    static func requestReview(in windowScene: UIWindowScene) {
        AppStore.requestReview(in: windowScene)
    }
}

struct InAppFeedbackCardViewModel {
    enum Feedback {
        case liked
        case didntLike
    }

    private let analytics: Analytics

    /// Closure invoked after the user has chosen what kind feedback to give.
    var onFeedbackGiven: ((Feedback) -> Void)?

    private let storeReviewRequesterType: AppStoreReviewRequesting.Type

    init(storeReviewRequesterType: AppStoreReviewRequesting.Type = AppStoreReviewRequester.self,
         analytics: Analytics = ServiceLocator.analytics) {
        self.storeReviewRequesterType = storeReviewRequesterType
        self.analytics = analytics
    }

    func didTapCouldBeBetter() {
        analytics.track(event: .appFeedbackPrompt(action: .didntLike))
        onFeedbackGiven?(.didntLike)
    }

    @MainActor
    func didTapILikeIt() {
        analytics.track(event: .appFeedbackPrompt(action: .liked))
        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive}) as? UIWindowScene {
            storeReviewRequesterType.requestReview(in: windowScene)
        }
        onFeedbackGiven?(.liked)
    }
}
