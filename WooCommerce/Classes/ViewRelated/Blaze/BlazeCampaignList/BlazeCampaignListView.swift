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
    private var coordinator: BlazeCampaignCreationCoordinator?
    private var startsCampaignCreationOnAppear: Bool

    /// View model for the list.
    private let viewModel: BlazeCampaignListViewModel

    init(viewModel: BlazeCampaignListViewModel,
         startsCampaignCreationOnAppear: Bool = false) {
        self.viewModel = viewModel
        self.startsCampaignCreationOnAppear = startsCampaignCreationOnAppear
        super.init(rootView: BlazeCampaignListView(viewModel: viewModel))

        rootView.onCreateCampaign = { [weak self] productID in
            self?.startCampaignCreation(productID: productID)
        }
    }

    @available(*, unavailable)
    required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if startsCampaignCreationOnAppear {
            startsCampaignCreationOnAppear = false
            startCampaignCreation()
        }
    }
}

/// Private helper
private extension BlazeCampaignListHostingController {
    func startCampaignCreation(productID: Int64? = nil) {
        guard let navigationController else {
            return
        }
        let coordinator = BlazeCampaignCreationCoordinator(
            siteID: viewModel.siteID,
            siteURL: viewModel.siteURL,
            productID: productID,
            source: .campaignList,
            shouldShowIntro: viewModel.shouldShowIntroView,
            navigationController: navigationController,
            onCampaignCreated: { [weak self] in
                self?.viewModel.didCreateCampaign()
            }
        )
        self.coordinator = coordinator
        coordinator.start()
    }
}

/// To be used in case we want to present BlazeCampaignListView from a SwiftUI view.
///
struct BlazeCampaignListHostingControllerRepresentable: UIViewControllerRepresentable {
    private let siteID: Int64
    private let selectedCampaignID: String?
    private let startsCampaignCreationOnAppear: Bool

    init(siteID: Int64,
         selectedCampaignID: String? = nil,
         startsCampaignCreationOnAppear: Bool = false) {
        self.siteID = siteID
        self.selectedCampaignID = selectedCampaignID
        self.startsCampaignCreationOnAppear = startsCampaignCreationOnAppear
    }
    func makeUIViewController(context: Context) -> BlazeCampaignListHostingController {

        let viewModel = BlazeCampaignListViewModel(siteID: siteID,
                                                   selectedCampaignID: selectedCampaignID ?? nil)
        return BlazeCampaignListHostingController(viewModel: viewModel,
                                                  startsCampaignCreationOnAppear: startsCampaignCreationOnAppear)
    }

    func updateUIViewController(_ uiViewController: BlazeCampaignListHostingController, context: Context) {
    }
}

/// View for showing a list of campaigns.
///
struct BlazeCampaignListView: View {
    @ObservedObject private var viewModel: BlazeCampaignListViewModel

    var onCreateCampaign: (Int64?) -> Void = { _ in }

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
                                viewModel.didSelectCampaignDetails(item.campaignID)
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
                    onCreateCampaign(nil)
                    viewModel.didSelectCreateCampaign(source: .campaignList)
                }
            }
        }
        .onAppear {
            viewModel.loadCampaigns()
            viewModel.onViewAppear()
        }
        .sheet(item: $viewModel.selectedCampaignURL, onDismiss: {
            viewModel.didDismissSelectedCampaign()
        }) { url in
            detailView(url: url)
        }
        .onChange(of: viewModel.shouldShowIntroView) { shouldShow in
            if shouldShow {
                onCreateCampaign(nil)
                viewModel.shouldShowIntroView = false
            }
        }
    }
}

private extension BlazeCampaignListView {

    func detailView(url: URL) -> some View {
        NavigationView {
            AuthenticatedWebView(
                isPresented: .constant(true),
                viewModel: BlazeCampaignDetailWebViewModel(initialURL: url, siteURL: viewModel.siteURL, onDismiss: {
                    viewModel.selectedCampaignURL = nil
                }, onCreateCampaign: { productID in
                    viewModel.selectedCampaignURL = nil
                    onCreateCampaign(productID)
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
    }
}

struct BlazeCampaignListView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeCampaignListView(viewModel: .init(siteID: 123))
    }
}
