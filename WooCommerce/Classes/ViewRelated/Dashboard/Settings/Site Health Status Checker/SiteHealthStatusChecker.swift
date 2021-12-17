import SwiftUI

/// List all the requests
///
struct SiteHealthStatusChecker: View {

    @ObservedObject private var viewModel: SiteHealthStatusCheckerViewModel
    @State private var showDetail = false

    init(siteID: Int64) {
        viewModel = SiteHealthStatusCheckerViewModel(siteID: siteID)
    }

    var body: some View {
        VStack {
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack {
                        ForEach(viewModel.requests) { request in
                            TitleAndSubtitleRow(title: request.actionName,
                                                subtitle: request.endpointName,
                                                isError: !request.success)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    showDetail = true
                                }
                            NavigationLink(destination:
                                            SiteHealthStatusCheckerDetail(request: request),
                                           isActive: $showDetail) {
                                EmptyView()
                            }
                                           .hidden()
                            Divider()
                        }
                    }
                    .renderedIf(!viewModel.shouldShowEmptyState)

                    emptyList
                        .renderedIf(viewModel.shouldShowEmptyState)
                        .frame(idealHeight: geometry.size.height)
                }
            }
            Button {
                Task {
                    await viewModel.startChecking()
                }
            } label: {
                Text(Localization.startChecking)
            }
            .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.isLoading))
            .disabled(viewModel.isLoading)
            .padding()
        }
    }

    private var emptyList: some View {
        VStack(alignment: .center) {
            EmptyState(title: Localization.emptyStateMessage, image: .errorImage)
        }
    }
}

private extension SiteHealthStatusChecker {
    enum Localization {
        static let startChecking = NSLocalizedString(
            "Start Checking",
            comment: "Button for starting the site health status checker")
        static let emptyStateMessage = NSLocalizedString(
            "Start checking your website's endpoints to check if something is not working properly.",
            comment: "Message displayed when there are no requests to display in the Site Health Status Checker")
    }
}

struct SiteHealthStatusChecker_Previews: PreviewProvider {
    static var previews: some View {
        SiteHealthStatusChecker(siteID: 123)
    }
}
