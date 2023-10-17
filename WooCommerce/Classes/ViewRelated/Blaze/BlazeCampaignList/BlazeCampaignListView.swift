import SwiftUI
import struct Yosemite.Site

/// Blaze campaign entry points.
enum BlazeCampaignSource: String {
    /// From the Blaze section on My Store tab.
    case myStoreSection = "my_store_section"
    /// From the Blaze campaign list
    case campaignList = "campaign_list"
}

/// Hosting controller for `BlazeCampaignListView`
///
final class BlazeCampaignListHostingController: UIHostingController<BlazeCampaignListView> {

    /// View model for the list.
    private let viewModel: BlazeCampaignListViewModel

    /// Whether the list is displayed right after a campaign is created.
    private let isPostCreation: Bool

    init(site: Site,
         viewModel: BlazeCampaignListViewModel,
         isPostCreation: Bool = false) {
        self.viewModel = viewModel
        self.isPostCreation = isPostCreation
        super.init(rootView: BlazeCampaignListView(viewModel: viewModel, siteURL: site.url.trimHTTPScheme()))

        rootView.onCreateCampaign = { [weak self] in
            let webViewModel = BlazeWebViewModel(source: .campaignList, site: site, productID: nil) {
                self?.handlePostCreation()
            }
            let webViewController = AuthenticatedWebViewController(viewModel: webViewModel)
            self?.navigationController?.show(webViewController, sender: self)
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

/// View for showing a list of campaigns.
///
struct BlazeCampaignListView: View {
    @ObservedObject private var viewModel: BlazeCampaignListViewModel
    @State private var selectedCampaignURL: URL?

    var onCreateCampaign: () -> Void = {}

    private let siteURL: String

    init(viewModel: BlazeCampaignListViewModel, siteURL: String) {
        self.viewModel = viewModel
        self.siteURL = siteURL
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
                                let path = String(format: Constants.campaignDetailsURLFormat,
                                                  item.campaignID, siteURL,
                                                  BlazeCampaignSource.campaignList.rawValue)
                                selectedCampaignURL = URL(string: path)
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
                }
            }
        }
        .onAppear {
            viewModel.loadCampaigns()
        }
        .sheet(item: $selectedCampaignURL) { url in
            detailView(url: url)
        }
        .sheet(isPresented: $viewModel.shouldDisplayPostCampaignCreationTip) {
            celebrationBottomSheet()
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
                        selectedCampaignURL = nil
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
    enum Constants {
        static let campaignDetailsURLFormat = "https://wordpress.com/advertising/campaigns/%d/%@?source=%@"
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
        BlazeCampaignListView(viewModel: .init(siteID: 123), siteURL: "https://example.com")
    }
}
