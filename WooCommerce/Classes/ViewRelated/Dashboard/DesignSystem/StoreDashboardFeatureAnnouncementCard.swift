import StoreDesignSystem
import SwiftUI

struct StoreDashboardFeatureAnnouncementCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let viewModel: AnnouncementCardViewModelProtocol
    let dismiss: () -> Void
    let callToAction: () -> Void

    var body: some View {
        StoreDashboardCardSurface {
            HStack(alignment: .bottom, spacing: StoreSpacing.s0) {
                VStack(alignment: .leading, spacing: StoreSpacing.s3) {
                    announcementBadge

                    Text(viewModel.title)
                        .storeTextStyle(.titleMedium.emphasized)
                        .foregroundStyle(.storeOnSurface)

                    Text(viewModel.message)
                        .storeTextStyle(.bodyMedium)
                        .foregroundStyle(.storeOnSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)

                    if let buttonTitle = viewModel.buttonTitle {
                        StoreButton(buttonTitle,
                                    variant: .outlined,
                                    action: performCallToAction)
                    }
                }
                .padding(StorePadding.p5)
                .padding(.trailing, dynamicTypeSize.isAccessibilitySize ? StorePadding.p7 : StorePadding.p3)
                .frame(maxWidth: .infinity, alignment: .leading)

                if !dynamicTypeSize.isAccessibilitySize {
                    announcementImage
                        .frame(maxWidth: Layout.imageWidth)
                }
            }
            .overlay(alignment: .topTrailing) {
                StoreDashboardCardOverflowMenu {
                    Button(Localization.hide, action: hideAnnouncement)
                }
                .padding(.top, StorePadding.p3)
                .padding(.trailing, StorePadding.p3)
            }
        }
        .onAppear(perform: viewModel.onAppear)
    }

    @ViewBuilder private var announcementBadge: some View {
        switch viewModel.badgeType {
        case .new:
            StoreBadge(Localization.newBadge)
        case .tip:
            StoreBadge(Localization.tipBadge)
        case .customText(let text):
            StoreBadge(text)
        case .remoteImage(let lightURL, let darkURL):
            AdaptiveAsyncImage(anyAppearanceUrl: lightURL, darkUrl: darkURL, scale: 3) { phase in
                if case .success(let image) = phase {
                    image
                        .scaledToFit()
                        .frame(height: StoreSize.badgeHeight)
                }
            }
        case nil:
            EmptyView()
        }
    }

    @ViewBuilder private var announcementImage: some View {
        if let imageURL = viewModel.imageUrl {
            AdaptiveAsyncImage(anyAppearanceUrl: imageURL,
                               darkUrl: viewModel.imageDarkUrl,
                               scale: 3) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit()
                case .empty:
                    Image(uiImage: viewModel.image).resizable().scaledToFit().redacted(reason: .placeholder)
                case .failure:
                    Image(uiImage: viewModel.image).resizable().scaledToFit()
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            Image(uiImage: viewModel.image)
                .resizable()
                .scaledToFit()
        }
    }

    private func performCallToAction() {
        viewModel.ctaTapped()
        callToAction()
    }

    private func hideAnnouncement() {
        viewModel.dontShowAgainTapped()
        dismiss()
    }
}

private extension StoreDashboardFeatureAnnouncementCard {
    enum Layout {
        static let imageWidth: CGFloat = 156
    }

    enum Localization {
        static let hide = NSLocalizedString(
            "storeDashboardFeatureAnnouncementCard.hide",
            value: "Hide this content",
            comment: "Menu action that hides a feature announcement from the dashboard."
        )
        static let newBadge = NSLocalizedString(
            "storeDashboardFeatureAnnouncementCard.badge.new",
            value: "New",
            comment: "Badge identifying a newly announced dashboard feature."
        )
        static let tipBadge = NSLocalizedString(
            "storeDashboardFeatureAnnouncementCard.badge.tip",
            value: "Tip",
            comment: "Badge identifying a dashboard feature tip."
        )
    }
}

#Preview("Feature announcement") {
    StoreDashboardFeatureAnnouncementCard(
        viewModel: StoreDashboardFeatureAnnouncementCardPreviewModel(),
        dismiss: {},
        callToAction: {}
    )
    .padding(StorePadding.p5)
    .background(Color.storeSurfaceDim)
}

#if DEBUG
import UIKit

struct StoreDashboardFeatureAnnouncementCardPreviewModel: AnnouncementCardViewModelProtocol {
    let showDividers = false
    let badgeType: BadgeView.BadgeType? = .new
    let title = "Get paid in person"
    let message = "Accept payments wherever you sell with WooCommerce point of sale."
    let buttonTitle: String? = "Learn more"
    let image = UIImage.paymentsFeatureBannerImage
    let imageUrl: URL? = nil
    let imageDarkUrl: URL? = nil
    let showDismissConfirmation = false
    let dismissAlertTitle = ""
    let dismissAlertMessage = ""

    func onAppear() {}
    func ctaTapped() {}
    func dontShowAgainTapped() {}
    func remindLaterTapped() {}
}
#endif
