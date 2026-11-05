import StoreDesignSystem
import SwiftUI
import class WooFoundation.MockAnalyticsPreview

struct StoreDashboardFeedbackCard: View {
    let viewModel: InAppFeedbackCardViewModel

    var body: some View {
        StoreDashboardCardSurface {
            VStack(spacing: StoreSpacing.s5) {
                Text(Localization.title)
                    .storeTextStyle(.titleMedium.emphasized)
                    .foregroundStyle(.storeOnSurface)
                    .multilineTextAlignment(.center)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: StoreSpacing.s5) {
                        feedbackButtons
                    }
                    VStack(spacing: StoreSpacing.s5) {
                        feedbackButtons
                    }
                }
            }
            .padding(StorePadding.p5)
        }
    }

    @ViewBuilder private var feedbackButtons: some View {
        StoreButton(Localization.couldBeBetter,
                    variant: .outlined,
                    size: .medium,
                    isFullWidth: true,
                    action: viewModel.didTapCouldBeBetter)
        StoreButton(Localization.iLikeIt,
                    size: .medium,
                    isFullWidth: true,
                    action: viewModel.didTapILikeIt)
    }
}

private extension StoreDashboardFeedbackCard {
    enum Localization {
        static let title = NSLocalizedString(
            "storeDashboardFeedbackCard.title",
            value: "Are you enjoying the app?",
            comment: "Title asking for feedback on the dashboard."
        )
        static let couldBeBetter = NSLocalizedString(
            "storeDashboardFeedbackCard.couldBeBetter",
            value: "Could be better",
            comment: "Button for giving negative feedback from the dashboard."
        )
        static let iLikeIt = NSLocalizedString(
            "storeDashboardFeedbackCard.iLikeIt",
            value: "I like it",
            comment: "Button for giving positive feedback from the dashboard."
        )
    }
}

#Preview("Feedback") {
    StoreDashboardFeedbackCard(
        viewModel: .init(
            storeReviewRequesterType: StoreDashboardFeedbackCardPreviewReviewRequester.self,
            analytics: MockAnalyticsPreview()
        )
    )
        .padding(StorePadding.p5)
        .background(Color.storeSurfaceDim)
}

#if DEBUG
import UIKit

@MainActor
enum StoreDashboardFeedbackCardPreviewReviewRequester: AppStoreReviewRequesting {
    static func requestReview(in windowScene: UIWindowScene) {}
}
#endif
