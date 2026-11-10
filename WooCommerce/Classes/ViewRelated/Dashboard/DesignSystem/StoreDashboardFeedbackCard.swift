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
                    horizontalButtonGroup
                    verticalButtonGroup
                }
            }
            .padding(StorePadding.p5)
        }
    }

    private var horizontalButtonGroup: some View {
        HStack(spacing: StoreSpacing.s5) {
            iLikeItButton(isTitleFixedSize: true)
            couldBeBetterButton(isTitleFixedSize: true)
        }
    }

    private var verticalButtonGroup: some View {
        VStack(spacing: StoreSpacing.s5) {
            iLikeItButton()
            couldBeBetterButton()
        }
    }

    private func iLikeItButton(isTitleFixedSize: Bool = false) -> StoreButton {
        StoreButton(Localization.iLikeIt,
                    size: .medium,
                    isFullWidth: true,
                    isTitleFixedSize: isTitleFixedSize,
                    action: viewModel.didTapILikeIt)
    }

    private func couldBeBetterButton(isTitleFixedSize: Bool = false) -> StoreButton {
        StoreButton(Localization.couldBeBetter,
                    variant: .outlined,
                    size: .medium,
                    isFullWidth: true,
                    isTitleFixedSize: isTitleFixedSize,
                    action: viewModel.didTapCouldBeBetter)
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
