import SwiftUI
import struct Yosemite.BlazeCampaign
import struct Yosemite.Product
import Kingfisher

/// Hosting controller for `BlazeCampaignDashboardView`.
///
final class BlazeCampaignDashboardViewHostingController: SelfSizingHostingController<BlazeCampaignDashboardView> {
    private let viewModel: BlazeCampaignDashboardViewModel
    private let parentNavigationController: UINavigationController?
    private lazy var blazeNavigationController = WooNavigationController()

    init(viewModel: BlazeCampaignDashboardViewModel, parentNavigationController: UINavigationController?) {
        self.viewModel = viewModel
        self.parentNavigationController = parentNavigationController

        super.init(rootView: BlazeCampaignDashboardView(viewModel: viewModel))
        if #unavailable(iOS 16.0) {
            viewModel.onStateChange = { [weak self] in
                self?.view.invalidateIntrinsicContentSize()
            }
        }

        rootView.createCampaignTapped = { [weak self] in
            self?.navigateToCampaignCreation(source: .myStoreSection)
        }

        rootView.startCampaignFromIntroTapped = { [weak self] productID in
            // Ensures the intro view is dismissed before navigating to the creation flow
            self?.parentNavigationController?.dismiss(animated: true) {
                self?.navigateToCampaignCreation(source: .introView, productID: productID)
            }
        }

        rootView.showAllCampaignsTapped = { [weak self] in
            self?.showCampaignList(isPostCreation: false)
        }
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension BlazeCampaignDashboardViewHostingController {

    private var productSelectorViewController: ProductSelectorViewController {
        let productSelectorViewModel = ProductSelectorViewModel(
            siteID: viewModel.siteID,
            purchasableItemsOnly: false,
            onProductSelectionStateChanged: { [weak self] product in
                guard let self = self else { return }

                // Navigate to Campaign Creation Form once any type of product is selected.
                self.navigateToNativeCampaignCreation(source: .myStoreSection,
                                                      productID: product.productID)
            },
            onCloseButtonTapped: { [weak self] in
                guard let self = self else { return }

                blazeNavigationController.dismiss(animated: true, completion: nil)
            }
        )

        return ProductSelectorViewController(configuration: ProductSelectorView.Configuration.configurationForBlaze,
                                             source: .blaze,
                                             viewModel: productSelectorViewModel)
    }

    /// Handles navigation to the campaign creation view.
    func navigateToCampaignCreation(source: BlazeSource, productID: Int64? = nil) {
        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.blazei3NativeCampaignCreation) {
            if let productID {
                navigateToNativeCampaignCreation(source: source, productID: productID)
            } else if viewModel.shouldShowProductSelectorView {
                navigateToBlazeProductSelector(source: source)
            } else if let product = viewModel.latestPublishedProduct {
                navigateToNativeCampaignCreation(source: source, productID: product.productID)
            } else {
                // Navigate to product selector as we don't have a product ID
                navigateToBlazeProductSelector(source: source)
            }
        } else {
            navigateToWebCampaignCreation(source: source, productID: productID)
        }
    }

    /// Handles navigation to the native Blaze creation
    func navigateToNativeCampaignCreation(source: BlazeSource, productID: Int64) {
        let campaignCreationFormViewModel = BlazeCampaignCreationFormViewModel(siteID: viewModel.siteID,
                                                                               productID: productID,
                                                                               onCompletion: { })
        let controller = BlazeCampaignCreationFormHostingController(viewModel: campaignCreationFormViewModel)
        // This function can be called from product selector, which is handled by BlazeNavigationController.
        // In this case, we need to show the controller from BlazeNavigationController.
        // Otherwise, we show it from the current navigation controller.
        if blazeNavigationController.presentingViewController != nil {
            blazeNavigationController.show(controller, sender: self)
        } else {
            self.navigationController?.show(controller, sender: self)
        }
    }

    /// Handles navigation to the Blaze product selector view
    func navigateToBlazeProductSelector(source: BlazeSource) {
        blazeNavigationController.viewControllers = [productSelectorViewController]
        parentNavigationController?.present(blazeNavigationController, animated: true, completion: nil)
    }

    /// Handles navigation to the webview Blaze creation
    func navigateToWebCampaignCreation(source: BlazeSource, productID: Int64? = nil) {
        let webViewModel = BlazeWebViewModel(siteID: viewModel.siteID,
                source: source,
                siteURL: viewModel.siteURL,
                productID: productID) { [weak self] in
            self?.handlePostCreation()
        }
        let webViewController = AuthenticatedWebViewController(viewModel: webViewModel)
        parentNavigationController?.show(webViewController, sender: self)
        viewModel.didSelectCreateCampaign(source: source)
    }

    /// Reloads data and shows campaign list.
    func handlePostCreation() {
        parentNavigationController?.popViewController(animated: true)
        Task {
            await viewModel.reload()
        }
        showCampaignList(isPostCreation: true)
    }

    /// Navigates to the campaign list.
    /// Parameter isPostCreation: Whether the list is opened after creating a campaign successfully.
    ///
    func showCampaignList(isPostCreation: Bool) {
        let controller = BlazeCampaignListHostingController(
            viewModel: .init(siteID: viewModel.siteID),
            isPostCreation: isPostCreation
        )
        parentNavigationController?.show(controller, sender: self)
    }
}

/// Blaze campaigns in dashboard screen.
struct BlazeCampaignDashboardView: View {

    /// Set externally in the hosting controller.
    var showAllCampaignsTapped: (() -> Void)?

    /// Set externally in the hosting controller.
    var createCampaignTapped: (() -> Void)?

    /// Set externally in the hosting controller.
    var startCampaignFromIntroTapped: ((_ productID: Int64?) -> Void)?

    @ObservedObject private var viewModel: BlazeCampaignDashboardViewModel
    @State private var selectedProductID: Int64?

    init(viewModel: BlazeCampaignDashboardViewModel) {
        self.viewModel = viewModel
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
                        selectedProductID = product.productID
                        viewModel.shouldShowIntroView = true
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
        .sheet(isPresented: $viewModel.shouldShowIntroView) {
            let onCreateCampaignClosure = {
                viewModel.shouldShowIntroView = false
                startCampaignFromIntroTapped?(selectedProductID)
            }
            let onDismissClosure = {
                viewModel.shouldShowIntroView = false
            }
            if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.blazei3NativeCampaignCreation) {
                BlazeCreateCampaignIntroView(onCreateCampaign: onCreateCampaignClosure,
                                             onDismiss: onDismissClosure)
            } else {
                BlazeCampaignIntroView(onStartCampaign: onCreateCampaignClosure,
                                       onDismiss: onDismissClosure)
            }
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
            viewModel.checkIfIntroViewIsNeeded()
            if !viewModel.shouldShowIntroView {
                createCampaignTapped?()
            }
        } label: {
            Text(Localization.createCampaign)
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

        static let createCampaign = NSLocalizedString(
            "Create campaign",
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
