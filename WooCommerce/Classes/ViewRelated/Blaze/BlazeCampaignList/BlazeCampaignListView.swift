import SwiftUI

/// Hosting controller for `BlazeCampaignListView`
///
final class BlazeCampaignListHostingController: UIHostingController<BlazeCampaignListView> {
    init(viewModel: BlazeCampaignListViewModel) {
        super.init(rootView: BlazeCampaignListView(viewModel: viewModel))
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

    init(viewModel: BlazeCampaignListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.items) {
                        BlazeCampaignItemView(campaign: $0)
                    }
                }
            }
            .navigationTitle(Localization.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.create) {
                        // TODO
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadCampaigns()
        }
    }
}

private extension BlazeCampaignListView {
    enum Localization {
        static let title = NSLocalizedString("Blaze Campaigns", comment: "Title of the Blaze campaign list view")
        static let create = NSLocalizedString("Create", comment: "Title of the button to create a new campaign on the Blaze campaign list view")
    }
}

struct BlazeCampaignListView_Previews: PreviewProvider {
    static var previews: some View {
        BlazeCampaignListView(viewModel: .init(siteID: 123))
    }
}
