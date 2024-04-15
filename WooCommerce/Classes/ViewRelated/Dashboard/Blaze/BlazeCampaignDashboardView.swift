import SwiftUI
import struct Yosemite.Product
import Kingfisher

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
            VStack(alignment: .leading, spacing: Layout.HeadingBlock.verticalSpacing) {
                // Title
                Text(Localization.title)
                    .fontWeight(.semibold)
                    .bodyStyle()

                // Subtitle
                Text(Localization.subtitle)
                    .fontWeight(.regular)
                    .subheadlineStyle()
                    .renderedIf(!viewModel.shouldShowShowAllCampaignsButton)
            }
            .redacted(reason: viewModel.shouldRedactView ? .placeholder : [])

            if case .showProduct(let product) = viewModel.state {
                ProductInfoView(product: product)
                    .onTapGesture {
                        createCampaignTapped?(product.productID)
                    }
            } else if case .showCampaign(let campaign) = viewModel.state {
                BlazeCampaignItemView(campaign: campaign, showBudget: false)
                    .onTapGesture {
                        viewModel.didSelectCampaignDetails(campaign)
                    }
            }

            // Show All Campaigns button
            showAllCampaignsButton
                .renderedIf(viewModel.shouldShowShowAllCampaignsButton)

            Divider()

            // Create campaign button
            createCampaignButton
                .redacted(reason: viewModel.shouldRedactView ? .placeholder : [])
        }
        .padding(insets: Layout.insets)
        .background(Color(uiColor: .listForeground(modal: false)))
        .sheet(item: $viewModel.selectedCampaignURL) { url in
            campaignDetailView(url: url)
        }
        .overlay {
            topRightMenu
                .renderedIf(viewModel.shouldRedactView == false)
        }
    }
}

private extension BlazeCampaignDashboardView {
    var topRightMenu: some View {
        VStack {
            HStack {
                Spacer()
                Menu {
                    Button(Localization.hideBlaze) {
                        viewModel.dismissBlazeSection()
                    }
                } label: {
                    Image(uiImage: .ellipsisImage)
                        .foregroundColor(Color(.textTertiary))
                }
            }
            Spacer()
        }
        .padding(Layout.insets)
    }

    var createCampaignButton: some View {
        Button {
            createCampaignTapped?(nil)
        } label: {
            Text(Localization.promote)
                .fontWeight(.semibold)
                .foregroundColor(.init(uiColor: .accent))
                .bodyStyle()
        }
    }

    var showAllCampaignsButton: some View {
        Button {
            viewModel.didSelectCampaignList()
            showAllCampaignsTapped?()
        } label: {
            HStack {
                Text(Localization.showAllCampaigns)
                    .fontWeight(.regular)
                    .bodyStyle()

                Spacer()

                // Chevron icon
                Image(uiImage: .chevronImage)
                    .flipsForRightToLeftLayoutDirection(true)
                    .foregroundColor(Color(.textTertiary))
            }
            .padding(insets: Layout.insets)
            .background(Color(uiColor: .init(light: UIColor.systemGray6,
                                             dark: UIColor.systemGray5)))
            .cornerRadius(Layout.cornerRadius)
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
        static let verticalSpacing: CGFloat = 16
        enum HeadingBlock {
            static let verticalSpacing: CGFloat = 8
        }
        static let insets: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let cornerRadius: CGFloat = 8
    }

    enum Localization {
        static let title = NSLocalizedString(
            "🔥 Blaze campaign",
            comment: "Title of the Blaze campaign view."
        )

        static let subtitle = NSLocalizedString(
            "Increase visibility and get your products sold quickly.",
            comment: "Subtitle of the Blaze campaign view."
        )

        static let showAllCampaigns = NSLocalizedString(
            "Show All Campaigns",
            comment: "Button when tapped will show the Blaze campaign list."
        )

        static let promote = NSLocalizedString(
            "blazeCampaignDashboardView.promote",
            value: "Promote",
            comment: "Button when tapped will launch create Blaze campaign flow."
        )

        static let done = NSLocalizedString("Done", comment: "Button to dismiss the Blaze campaign detail view")

        static let detailTitle = NSLocalizedString("Campaign Details", comment: "Title of the Blaze campaign details view.")

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

            Text(product.name)
                .fontWeight(.semibold)
                .foregroundColor(.init(UIColor.text))
                .subheadlineStyle()
                .multilineTextAlignment(.leading)
                // This size modifier is necessary so that the product name is never truncated.
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            // Chevron icon
            Image(uiImage: .chevronImage)
                .flipsForRightToLeftLayoutDirection(true)
                .foregroundColor(Color(.textTertiary))
        }
        .padding(Layout.contentPadding)
        .background(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(Color(uiColor: .init(light: UIColor.clear,
                                           dark: UIColor.systemGray5)))
        )
        .overlay {
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color(uiColor: .separator), lineWidth: Layout.strokeWidth)
        }
    }

    private enum Layout {
        static let imageSize: CGFloat = 44
        static let contentSpacing: CGFloat = 16
        static let contentPadding: CGFloat = 16
        static let strokeWidth: CGFloat = 0.5
        static let cornerRadius: CGFloat = 8
    }
}


struct BlazeCampaignDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeCampaignDashboardView(viewModel: .init(siteID: 0))
    }
}
