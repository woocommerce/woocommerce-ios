import SwiftUI

/// Hosting controller for `BlazeCampaignListView`
///
final class BlazeCampaignListHostingController: UIHostingController<BlazeCampaignListView> {
    init(viewModel: BlazeCampaignListViewModel) {

        super.init(rootView: BlazeCampaignListView(viewModel: viewModel))

        rootView.onCreateCampaign = { [weak self] in
            guard let site = ServiceLocator.stores.sessionManager.defaultSite else {
                return
            }
            let viewModel = BlazeWebViewModel(source: .campaignList, site: site, productID: nil)
            let webViewController = AuthenticatedWebViewController(viewModel: viewModel)
            self?.navigationController?.show(webViewController, sender: self)
        }
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
            "Boost your sales by promoting your products",
            comment: "Subtitle of the empty state of the Blaze campaign list view"
        )
    }
}

struct BlazeCampaignListView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeCampaignListView(viewModel: .init(siteID: 123))
    }
}
