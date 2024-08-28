import SwiftUI
import struct Yosemite.Product
import Kingfisher
import struct Yosemite.DashboardCard

/// Hosting controller for `BlazeCampaignDashboardView`.
///
final class BlazeCampaignDashboardViewHostingController: SelfSizingHostingController<BlazeCampaignDashboardView> {
    private let viewModel: BlazeCampaignDashboardViewModel
    private let parentNavigationController: UINavigationController
    private lazy var blazeNavigationController = WooNavigationController()
    private var coordinator: BlazeCampaignCreationCoordinator?

    init(viewModel: BlazeCampaignDashboardViewModel, parentNavigationController: UINavigationController) {
        self.viewModel = viewModel
        self.parentNavigationController = parentNavigationController

        super.init(rootView: BlazeCampaignDashboardView(viewModel: viewModel))
        if #unavailable(iOS 16.0) {
            viewModel.onStateChange = { [weak self] in
                self?.view.invalidateIntrinsicContentSize()
            }
        }

        rootView.createCampaignTapped = { [weak self] productID in
            guard let self else { return }
            let coordinator = BlazeCampaignCreationCoordinator(
                    siteID: viewModel.siteID,
                    siteURL: viewModel.siteURL,
                    productID: productID,
                    source: .myStoreSection,
                    shouldShowIntro: viewModel.shouldShowIntroView,
                    navigationController: parentNavigationController,
                    onCampaignCreated: handlePostCreation
                )
            coordinator.start()
            self.coordinator = coordinator
        }

        rootView.showAllCampaignsTapped = { [weak self] in
            self?.showCampaignList()
        }
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension BlazeCampaignDashboardViewHostingController {
    /// Reloads data.
    func handlePostCreation() {
        viewModel.didCreateCampaign()
    }

    /// Navigates to the campaign list.
    /// Parameter isPostCreation: Whether the list is opened after creating a campaign successfully.
    ///
    func showCampaignList() {
        let controller = BlazeCampaignListHostingController(viewModel: .init(siteID: viewModel.siteID))
        parentNavigationController.show(controller, sender: self)
    }
}

/// Blaze campaigns in dashboard screen.
struct BlazeCampaignDashboardView: View {
    /// Scale of the view based on accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0

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
        VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
            header
                .padding(.horizontal, Layout.padding)

            switch viewModel.state {
            case .showProduct(let product):
                ProductInfoView(product: product)
                    .padding(.horizontal, Layout.padding)
                    .onTapGesture {
                        createCampaignTapped?(product.productID)
                    }
            case .showCampaign(let campaign):
                BlazeCampaignItemView(campaign: campaign)
                    .padding(.horizontal, Layout.padding)
                    .onTapGesture {
                        viewModel.didSelectCampaignDetails(campaign)
                    }
            case .empty:
                DashboardCardErrorView(onRetry: {
                    ServiceLocator.analytics.track(event: .DynamicDashboard.cardRetryTapped(type: .blaze))
                    Task {
                        await viewModel.reload()
                    }
                })
                .padding(.horizontal, Layout.padding)
            case .loading:
                EmptyView()
            }

            // Create campaign button
            createCampaignButton
                .padding(.horizontal, Layout.padding)
                .redacted(reason: viewModel.shouldRedactView ? .placeholder : [])
                .shimmering(active: viewModel.shouldRedactView)
                .renderedIf(viewModel.shouldShowCreateCampaignButton)

            // Show All Campaigns button
            VStack(spacing: 0) {
                Divider()
                    .padding(.leading, Layout.padding)
                    .padding(.bottom, Layout.dividerVerticalSpacing)
                showAllCampaignsButton
                    .padding(.horizontal, Layout.padding)
            }
            .renderedIf(viewModel.shouldShowShowAllCampaignsButton)

        }
        .padding(.vertical, Layout.padding)
        .background(Color(.listForeground(modal: false)))
        .clipShape(RoundedRectangle(cornerSize: Layout.cornerSize))
        .padding(.horizontal, Layout.padding)
        .sheet(item: $viewModel.selectedCampaignURL) { url in
            campaignDetailView(url: url)
        }
    }
}

private extension BlazeCampaignDashboardView {
    var header: some View {
        VStack(alignment: .leading, spacing: Layout.HeadingBlock.verticalSpacing) {
            // Title
            HStack {
                Image(uiImage: .blaze)
                    .resizable()
                    .frame(width: Layout.logoSize * scale, height: Layout.logoSize * scale)
                Text(DashboardCard.CardType.blaze.name)
                    .headlineStyle()
                Spacer()
                Menu {
                    Button(Localization.hideBlaze) {
                        viewModel.dismissBlazeSection()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Color.secondary)
                        .padding(.leading, Layout.padding)
                        .padding(.vertical, Layout.hideIconVerticalPadding)
                }
                .disabled(viewModel.shouldRedactView)
            }
            // Subtitle
            Text(Localization.subtitle)
                .fontWeight(.regular)
                .subheadlineStyle()
                .renderedIf(viewModel.shouldShowSubtitle)
        }

    }

    var createCampaignButton: some View {
        Button {
            createCampaignTapped?(nil)
        } label: {
            Text(Localization.createCampaign)
                .bodyStyle()
        }
        .buttonStyle(SecondaryButtonStyle())
    }

    var showAllCampaignsButton: some View {
        Button {
            viewModel.didSelectCampaignList()
            showAllCampaignsTapped?()
        } label: {
            HStack(spacing: 0) {
                Text(Localization.showAllCampaigns)
                    .fontWeight(.regular)
                    .foregroundStyle(Color.accentColor)
                    .bodyStyle()

                Spacer()

                // Chevron icon
                Image(uiImage: .chevronImage)
                    .flipsForRightToLeftLayoutDirection(true)
                    .foregroundStyle(Color(.textTertiary))
            }
        }
    }

    func campaignDetailView(url: URL) -> some View {
        NavigationView {
            AuthenticatedWebView(isPresented: .constant(true),
                                 url: url)
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

private extension BlazeCampaignDashboardView {
    enum Layout {
        static let padding: CGFloat = 16
        static let cornerSize = CGSize(width: 8.0, height: 8.0)
        static let verticalSpacing: CGFloat = 16
        enum HeadingBlock {
            static let verticalSpacing: CGFloat = 8
        }
        static let cornerRadius: CGFloat = 8
        static let logoSize: CGFloat = 20
        static let hideIconVerticalPadding: CGFloat = 8
        static let dividerVerticalSpacing: CGFloat = 16
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

    private let product: Product

    init(product: Product) {
        self.product = product
    }

    var body: some View {
        HStack(alignment: .center, spacing: Layout.contentSpacing) {
            KFImage(product.imageURL)
                .placeholder {
                    Image(uiImage: .productPlaceholderImage)
                }
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: Layout.imageSize * scale, height: Layout.imageSize * scale)
                .cornerRadius(Layout.cornerRadius)

            VStack(alignment: .leading) {
                Text(Localization.suggestedProductLabel)
                    .foregroundStyle(Color(.textSubtle))
                    .captionStyle()

                Text(product.name)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(.text))
                    .subheadlineStyle()
                    .multilineTextAlignment(.leading)
                    // This size modifier is necessary so that the product name is never truncated.
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Chevron icon
            Image(uiImage: .chevronImage)
                .flipsForRightToLeftLayoutDirection(true)
                .foregroundStyle(Color(.textTertiary))
        }
        .padding(Layout.contentPadding)
        .background(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(Color(uiColor: .init(light: UIColor.clear,
                                           dark: UIColor.systemGray5)))
        )
        .overlay {
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color(uiColor: .secondaryButtonDownBorder), lineWidth: Layout.strokeWidth)
        }
    }

    private enum Layout {
        static let imageSize: CGFloat = 44
        static let contentSpacing: CGFloat = 16
        static let contentPadding: CGFloat = 16
        static let strokeWidth: CGFloat = 1
        static let cornerRadius: CGFloat = 8
    }

    private enum Localization {
        static let suggestedProductLabel = NSLocalizedString(
            "productInfoView.suggestedProductLabel",
            value: "Suggested product",
            comment: "Label for the suggested product on the Blaze dashboard view."
        )
    }
}


struct BlazeCampaignDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeCampaignDashboardView(viewModel: .init(siteID: 0))
    }
}
