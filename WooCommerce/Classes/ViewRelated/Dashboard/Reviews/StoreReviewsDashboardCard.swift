import StoreDesignSystem
import SwiftUI
import struct Yosemite.DashboardCard
import struct Yosemite.ProductReview

/// SwiftUI view for the Reviews dashboard card
///
struct StoreReviewsDashboardCard: View {
    @ObservedObject private var viewModel: ReviewsDashboardCardViewModel
    private let onViewAllReviews: (() -> Void)
    private let onViewReviewDetail: ((_ review: ReviewViewModel) -> Void)

    init(viewModel: ReviewsDashboardCardViewModel,
         onViewAllReviews: @escaping () -> Void,
         onViewReviewDetail: @escaping (_ review: ReviewViewModel) -> Void) {
        self.viewModel = viewModel
        self.onViewAllReviews = onViewAllReviews
        self.onViewReviewDetail = onViewReviewDetail
    }

    var body: some View {
        StoreDashboardCardSurface {
            VStack(alignment: .leading, spacing: StoreSpacing.s0) {
                header

                if viewModel.syncingError != nil {
                    errorState
                } else {
                    reviewsFilterBar
                    StoreDivider()

                    if viewModel.syncingData {
                        loadingStateView
                    } else if viewModel.data.isNotEmpty {
                        reviewList
                    } else {
                        emptyView
                    }

                    StoreDashboardCardFooterAction(Localization.viewAll,
                                                   isDisabled: viewModel.syncingData,
                                                   action: viewAllReviews)
                }
            }
        }
    }
}

private extension StoreReviewsDashboardCard {
    var header: some View {
        StoreDashboardCardHeader(DashboardCard.CardType.reviews.name,
                                 showsError: viewModel.syncingError != nil) {
            StoreDashboardCardOverflowMenu(isDisabled: viewModel.syncingData) {
                Button(Localization.hideCard, action: viewModel.dismissReviews)
            }
        }
    }

    var reviewsFilterBar: some View {
        StoreDashboardCardFilterHeader(
            title: Localization.status,
            selectedOptionTitle: viewModel.currentFilter.title,
            options: viewModel.filters,
            isDisabled: viewModel.syncingData,
            optionTitle: { $0.title },
            isSelected: { $0 == viewModel.currentFilter },
            onSelect: selectFilter
        )
    }

    var loadingStateView: some View {
        ForEach(ReviewsDashboardCardViewModel.placeholderData, id: \.review.reviewID) { reviewViewModel in
            StoreReviewDashboardRow(viewModel: reviewViewModel,
                                    highlightsUnread: false,
                                    onTap: {})
        }
        .redacted(reason: .placeholder)
        .shimmering()
    }

    var reviewList: some View {
        VStack(spacing: StoreSpacing.s0) {
            ForEach(viewModel.data, id: \.review.reviewID) { review in
                StoreReviewDashboardRow(
                    viewModel: review,
                    highlightsUnread: viewModel.shouldHighlightAsUnread(review),
                    onTap: { showReviewDetail(review) }
                )
            }
        }
    }

    var errorState: some View {
        StoreDashboardCardErrorView {
            ServiceLocator.analytics.track(event: .DynamicDashboard.cardRetryTapped(type: .reviews))
            Task { await viewModel.reloadData() }
        }
    }

    func selectFilter(_ filter: ReviewsDashboardCardViewModel.ReviewsFilter) {
        ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .reviews))
        Task { await viewModel.filterReviews(by: filter) }
    }

    var emptyView: some View {
        VStack(alignment: .center, spacing: StoreSpacing.s5) {
            Image(uiImage: .messageImage)
                .accessibilityHidden(true)
            Text(emptyViewText(isFiltered: viewModel.currentFilter != .all))
                .storeTextStyle(.titleLarge.strong)
                .foregroundStyle(.storeOnSurface)
                .multilineTextAlignment(.center)
        }
        .padding(StorePadding.p5)
        .frame(maxWidth: .infinity)
    }

    func showReviewDetail(_ review: ReviewViewModel) {
        ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .reviews))
        onViewReviewDetail(review)
    }

    func viewAllReviews() {
        ServiceLocator.analytics.track(event: .DynamicDashboard.dashboardCardInteracted(type: .reviews))
        onViewAllReviews()
    }

    func emptyViewText(isFiltered: Bool) -> String {
        if isFiltered {
            return String.localizedStringWithFormat(Localization.noFilteredReviewsText, viewModel.currentFilter.title)
        } else {
            return Localization.noReviewsText
        }
    }
}

private extension StoreReviewsDashboardCard {
    typealias Localization = ReviewsDashboardCard.Localization
}

#Preview {
    StoreReviewsDashboardCard(viewModel: ReviewsDashboardCardViewModel(siteID: 1),
                         onViewAllReviews: { },
                         onViewReviewDetail: { _ in })
}
