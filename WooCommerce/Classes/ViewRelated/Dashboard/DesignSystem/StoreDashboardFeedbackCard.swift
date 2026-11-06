import StoreDesignSystem
import SwiftUI

struct StoreDashboardFeedbackCard: View {
    let viewModel: InAppFeedbackCardViewModel

    var body: some View {
        StoreDashboardCardSurface {
            VStack(spacing: StoreSpacing.s5) {
                Text(Localization.feedbackTitle)
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
    typealias Localization = InAppFeedbackCardView.Localization
}

#if DEBUG
import UIKit
import class WooFoundation.MockAnalyticsPreview

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

@MainActor
enum StoreDashboardFeedbackCardPreviewReviewRequester: AppStoreReviewRequesting {
    static func requestReview(in windowScene: UIWindowScene) {}
}
#endif
