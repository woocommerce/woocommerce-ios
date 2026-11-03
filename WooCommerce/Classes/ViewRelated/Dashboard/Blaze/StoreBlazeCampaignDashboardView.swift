import Kingfisher
import StoreDesignSystem
import SwiftUI
import struct Yosemite.DashboardCard

/// Blaze campaigns in dashboard screen.
struct StoreBlazeCampaignDashboardView: View {
    /// Set externally in the hosting controller.
    var showAllCampaignsTapped: (() -> Void)?

    /// Set externally in the hosting controller.
    var createCampaignTapped: ((_ productID: Int64?) -> Void)?

    @ObservedObject private var viewModel: BlazeCampaignDashboardViewModel

    init(viewModel: BlazeCampaignDashboardViewModel,
         showAllCampaignsTapped: (() -> Void)? = nil,
         createCampaignTapped: ((_ productID: Int64?) -> Void)? = nil) {
        self.viewModel = viewModel
        self.showAllCampaignsTapped = showAllCampaignsTapped
        self.createCampaignTapped = createCampaignTapped
    }

    var body: some View {
        StoreDashboardCardSurface {
            VStack(alignment: .leading, spacing: StoreSpacing.s0) {
                header

                if showsError {
                    errorState
                } else {
                    VStack(alignment: .leading, spacing: StoreSpacing.s5) {
                        Text(Localization.subtitle)
                            .storeTextStyle(.bodyLarge)
                            .foregroundStyle(.storeOnSurface)
                            .renderedIf(viewModel.shouldShowSubtitle)

                        switch viewModel.state {
                        case .showProduct(let product):
                            Button {
                                createCampaignTapped?(product.productID)
                            } label: {
                                ProductInfoView(product: product)
                            }
                            .buttonStyle(.plain)
                        case .showCampaign(let campaign):
                            Button {
                                viewModel.didSelectCampaignDetails(campaign)
                            } label: {
                                StoreBlazeCampaignItemView(campaign: campaign)
                            }
                            .buttonStyle(.plain)
                        case .empty, .loading:
                            EmptyView()
                        }

                        StoreButton(Localization.createCampaign,
                                    variant: .outlined,
                                    isFullWidth: true,
                                    action: createCampaign)
                            .redacted(reason: viewModel.shouldRedactView ? .placeholder : [])
                            .shimmering(active: viewModel.shouldRedactView)
                            .renderedIf(viewModel.shouldShowCreateCampaignButton)
                    }
                    .padding(.horizontal, StorePadding.p5)
                    .padding(.bottom, StorePadding.p5)

                    StoreDashboardCardFooterAction(Localization.showAllCampaigns, action: showAllCampaigns)
                        .renderedIf(viewModel.shouldShowShowAllCampaignsButton)
                }
            }
        }
        .sheet(item: $viewModel.selectedCampaignURL, onDismiss: {
            viewModel.didDismissSelectedCampaign()
        }) { url in
            campaignDetailView(url: url)
        }
    }
}

private extension StoreBlazeCampaignDashboardView {
    var header: some View {
        HStack(spacing: StoreSpacing.s5) {
            if showsError {
                Image(systemName: "exclamationmark.circle")
                    .imageScale(.large)
                    .foregroundStyle(.storeOnSurfaceVariant)
                    .accessibilityHidden(true)
            } else {
                Image(uiImage: .blaze)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Layout.logoSize, height: Layout.logoSize)
                    .accessibilityHidden(true)
            }

            Text(DashboardCard.CardType.blaze.name)
                .storeTextStyle(.titleSmall.emphasized)
                .foregroundStyle(.storeOnSurface)
                .padding(.vertical, StorePadding.p7)
                .frame(maxWidth: .infinity, alignment: .leading)

            StoreDashboardCardOverflowMenu(isDisabled: viewModel.shouldRedactView) {
                Button(Localization.hideBlaze, action: viewModel.dismissBlazeSection)
            }
        }
        .padding(.horizontal, StorePadding.p5)
    }

    var showsError: Bool {
        if case .empty = viewModel.state {
            true
        } else {
            false
        }
    }

    var errorState: some View {
        StoreDashboardCardErrorView {
            ServiceLocator.analytics.track(event: .DynamicDashboard.cardRetryTapped(type: .blaze))
            Task { await viewModel.reload() }
        }
    }

    func createCampaign() {
        createCampaignTapped?(nil)
    }

    func showAllCampaigns() {
        viewModel.didSelectCampaignList()
        showAllCampaignsTapped?()
    }

    func campaignDetailView(url: URL) -> some View {
        NavigationStack {
            AuthenticatedWebView(
                isPresented: .constant(true),
                viewModel: BlazeCampaignDetailWebViewModel(initialURL: url, siteURL: viewModel.siteURL, onDismiss: {
                    viewModel.selectedCampaignURL = nil
                }, onCreateCampaign: { productID in
                    viewModel.selectedCampaignURL = nil
                    createCampaignTapped?(productID)
                }))
            .navigationTitle(Localization.detailTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        viewModel.selectedCampaignURL = nil
                    }, label: {
                        Text(Localization.done)
                    })
                }
            }
        }
    }
}

private extension StoreBlazeCampaignDashboardView {
    enum Layout {
        static let logoSize: CGFloat = 24
    }

    enum Localization {

        static let subtitle = NSLocalizedString(
            "blazeCampaignDashboardView.subtitle",
            value: "Increase visibility and get your products sold quickly.",
            comment: "Subtitle of the Blaze campaign view."
        )

        static let showAllCampaigns = NSLocalizedString(
            "blazeCampaignDashboardView.showAllCampaigns",
            value: "View all campaigns",
            comment: "Button when tapped will show the Blaze campaign list."
        )

        static let createCampaign = NSLocalizedString(
            "blazeCampaignDashboardView.createCampaign",
            value: "Create Campaign",
            comment: "Button that when tapped will launch create Blaze campaign flow."
        )

        static let done = NSLocalizedString(
            "blazeCampaignDashboardView.done",
            value: "Done",
            comment: "Button to dismiss the Blaze campaign detail view"
        )

        static let detailTitle = NSLocalizedString(
            "blazeCampaignDashboardView.detailTitle",
            value: "Campaign Details",
            comment: "Title of the Blaze campaign details view."
        )

        static let hideBlaze = NSLocalizedString(
            "blazeCampaignDashboardView.hideBlazeButton",
            value: "Hide Blaze",
            comment: "Button to dismiss the Blaze campaign section on the My Store screen."
        )
    }
}

private struct ProductInfoView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

    private let product: BlazeCampaignProduct

    init(product: BlazeCampaignProduct) {
        self.product = product
    }

    var body: some View {
        StoreDashboardOutlinedContent {
            HStack(alignment: .center, spacing: StoreSpacing.s5) {
                KFImage(product.firstImage?.imageURL)
                    .placeholder { Image(uiImage: .productPlaceholderImage) }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: Layout.imageSize * scale, height: Layout.imageSize * scale)
                    .clipShape(.rect(cornerRadius: StoreRadius.medium))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: StoreSpacing.s2) {
                    Text(Localization.suggestedProductLabel)
                        .storeTextStyle(.bodySmall)

                    Text(product.name)
                        .storeTextStyle(.titleMedium.strong)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: StoreSpacing.s0)

                StoreIcon.AngleRight.regular.image(size: .largeIncreased)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(.storeOnSurface)
        }
    }

    private enum Layout {
        static let imageSize: CGFloat = 44
    }

    private enum Localization {
        static let suggestedProductLabel = NSLocalizedString(
            "productInfoView.suggestedProductLabel",
            value: "Suggested product",
            comment: "Label for the suggested product on the Blaze dashboard view."
        )
    }
}

#Preview {
    StoreBlazeCampaignDashboardView(viewModel: .init(siteID: 0))
}
