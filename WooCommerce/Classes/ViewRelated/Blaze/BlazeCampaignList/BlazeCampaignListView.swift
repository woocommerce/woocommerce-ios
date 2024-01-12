import SwiftUI
import struct Yosemite.Site

/// Blaze campaign detail entry points.
enum BlazeCampaignDetailSource: String {
    /// From the Blaze section on My Store tab.
    case myStoreSection = "my_store_section"
    /// From the Blaze campaign list
    case campaignList = "campaign_list"
}

enum BlazeCampaignListSource: String {
    /// From the Menu tab
    case menu
    /// From the Blaze section on My Store tab
    case myStoreSection = "my_store_section"
}

/// Hosting controller for `BlazeCampaignListView`
///
final class BlazeCampaignListHostingController: UIHostingController<BlazeCampaignListView> {
    private lazy var blazeNavigationController = WooNavigationController()

    /// View model for the list.
    private let viewModel: BlazeCampaignListViewModel

    /// Whether the list is displayed right after a campaign is created.
    private let isPostCreation: Bool

    init(viewModel: BlazeCampaignListViewModel,
         isPostCreation: Bool = false) {
        self.viewModel = viewModel
        self.isPostCreation = isPostCreation
        super.init(rootView: BlazeCampaignListView(viewModel: viewModel))

        rootView.onCreateCampaign = { [weak self] in
            self?.navigateToCampaignCreation()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if isPostCreation {
            viewModel.checkIfPostCreationTipIsNeeded()
        }
    }

    func handlePostCreation() {
        navigationController?.popViewController(animated: true)
        viewModel.loadCampaigns()
        viewModel.checkIfPostCreationTipIsNeeded()
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Navigation related
private extension BlazeCampaignListHostingController {
    /// Handles navigation to the different campaign creation views.
    func navigateToCampaignCreation() {
        switch viewModel.createCampaignDestination {
        case .productSelector:
            navigateToBlazeProductSelector(source: .campaignList)
        case .campaignForm(let productID):
            navigateToNativeCampaignCreation(source: .campaignList, productID: productID)
        case .webviewForm(let productID):
            navigateToWebCampaignCreation(source: .campaignList, productID: productID)
        case .noProductAvailable:
            break // Todo add error alert.
        }
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
        self.navigationController?.show(webViewController, sender: self)
        viewModel.didSelectCreateCampaign(source: source)
    }

    /// Handles navigation to the native Blaze creation
    func navigateToNativeCampaignCreation(source: BlazeSource, productID: Int64) {
        let campaignCreationFormViewModel = BlazeCampaignCreationFormViewModel(siteID: viewModel.siteID,
                                                                               productID: productID,
                                                                               onCompletion: { })
        let controller = BlazeCampaignCreationFormHostingController(viewModel: campaignCreationFormViewModel)

        if blazeNavigationController.presentingViewController != nil {
            blazeNavigationController.show(controller, sender: self)
        } else {
            blazeNavigationController.viewControllers = [controller]
            self.navigationController?.present(blazeNavigationController, animated: true)
        }
    }

    // View controller for product selector before going to campaign creation form.
    private var productSelectorViewController: ProductSelectorViewController {
        let productSelectorViewModel = ProductSelectorViewModel(
            siteID: viewModel.siteID,
            purchasableItemsOnly: false,
            onProductSelectionStateChanged: { [weak self] product in
                guard let self = self else { return }

                // Navigate to Campaign Creation Form once any type of product is selected.
                self.navigateToNativeCampaignCreation(source: .campaignList, productID: product.productID)
            },
            onCloseButtonTapped: { [weak self] in
                guard let self = self else { return }

                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        )

        return ProductSelectorViewController(configuration: ProductSelectorView.Configuration.configurationForBlaze,
                                             source: .blaze,
                                             viewModel: productSelectorViewModel)
    }

    /// Handles navigation to the Blaze product selector view
    func navigateToBlazeProductSelector(source: BlazeSource) {
        blazeNavigationController.viewControllers = [productSelectorViewController]
        self.navigationController?.present(blazeNavigationController, animated: true, completion: nil)
    }
}

/// View for showing a list of campaigns.
///
struct BlazeCampaignListView: View {
    @ObservedObject private var viewModel: BlazeCampaignListViewModel

    var onCreateCampaign: () -> Void = {}


    init(viewModel: BlazeCampaignListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            switch viewModel.syncState {
            case .results:
                RefreshableInfiniteScrollList(spacing: Layout.contentSpacing,
                                              isLoading: viewModel.shouldShowBottomActivityIndicator,
                                              loadAction: viewModel.onLoadNextPageAction,
                                              refreshAction: { completion in
                    viewModel.onRefreshAction(completion: completion)
                }) {
                    ForEach(viewModel.campaigns) { item in
                        BlazeCampaignItemView(campaign: item)
                            .onTapGesture {
                                viewModel.didSelectCampaignDetails(item)
                            }
                    }
                }
            case .empty:
                EmptyState(title: Localization.emptyStateTitle,
                           description: Localization.emptyStateMessage,
                           image: .emptyProductsImage)
                    .frame(maxHeight: .infinity)
            case .syncingFirstPage:
                ActivityIndicator(isAnimating: .constant(true), style: .medium)
            }
        }
        .padding(Layout.contentSpacing)
        .navigationTitle(Localization.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(Localization.create) {
                    onCreateCampaign()
                    viewModel.didSelectCreateCampaign(source: .campaignList)
                }
            }
        }
        .onAppear {
            viewModel.loadCampaigns()
            viewModel.onViewAppear()
        }
        .sheet(item: $viewModel.selectedCampaignURL) { url in
            detailView(url: url)
        }
        .sheet(isPresented: $viewModel.shouldDisplayPostCampaignCreationTip) {
            celebrationBottomSheet()
        }
        .sheet(isPresented: $viewModel.shouldShowIntroView) {
            let onCreateCampaignClosure = {
                viewModel.shouldShowIntroView = false
                onCreateCampaign()
                viewModel.didSelectCreateCampaign(source: .introView)
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
    }
}

private extension BlazeCampaignListView {
    var celebrationView: some View {
        CelebrationView(title: Localization.celebrationTitle,
                        subtitle: Localization.celebrationSubtitle,
                        closeButtonTitle: Localization.celebrationCTA,
                        onTappingDone: {
            viewModel.shouldDisplayPostCampaignCreationTip = false
        })
    }

    @ViewBuilder
    func celebrationBottomSheet() -> some View {
        if #available(iOS 16.0, *) {
            celebrationView
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        } else {
            celebrationView
        }
    }

    func detailView(url: URL) -> some View {
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

private extension BlazeCampaignListView {
    enum Layout {
        static let contentSpacing: CGFloat = 16
    }
    enum Localization {
        static let title = NSLocalizedString("Blaze Campaigns", comment: "Title of the Blaze campaign list view")
        static let create = NSLocalizedString("Create", comment: "Title of the button to create a new campaign on the Blaze campaign list view")
        static let emptyStateTitle = NSLocalizedString("No campaigns yet", comment: "Title of the empty state of the Blaze campaign list view")
        static let emptyStateMessage = NSLocalizedString(
            "Drive more sales to your store with Blaze",
            comment: "Subtitle of the empty state of the Blaze campaign list view"
        )
        static let done = NSLocalizedString("Done", comment: "Button to dismiss the Blaze campaign detail view")
        static let detailTitle = NSLocalizedString("Campaign Details", comment: "Title of the Blaze campaign details view.")
        static let celebrationTitle = NSLocalizedString(
            "All set!",
            comment: "Title of the celebration view when a Blaze campaign is successfully created."
        )
        static let celebrationSubtitle = NSLocalizedString(
            "The ad has been submitted for approval. We'll send you a confirmation email once it's approved and running.",
            comment: "Subtitle of the celebration view when a Blaze campaign is successfully created."
        )
        static let celebrationCTA = NSLocalizedString(
            "Got it",
            comment: "Button to dismiss the celebration view when a Blaze campaign is successfully created."
        )
    }
}

struct BlazeCampaignListView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeCampaignListView(viewModel: .init(siteID: 123, siteURL: "https://example.com"))
    }
}
