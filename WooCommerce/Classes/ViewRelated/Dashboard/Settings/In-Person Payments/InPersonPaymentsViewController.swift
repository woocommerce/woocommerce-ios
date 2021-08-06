import SwiftUI

final class InPersonPaymentsViewController: UIHostingController<InPersonPaymentsView> {
    init(viewModel: InPersonPaymentsViewModel) {
        super.init(rootView: InPersonPaymentsView(viewModel: viewModel))
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct InPersonPaymentsView: View {
    @StateObject var viewModel: InPersonPaymentsViewModel

    var body: some View {
        Group {
            switch viewModel.state {
            case .wcpayNotInstalled:
                InPersonPaymentsPluginNotInstalled(onRefresh: viewModel.refresh)
            case .completed:
                CardReaderSettingsPresentingView()
            default:
                InPersonPaymentsUnavailableView()
            }
        }
        .navigationTitle(Localization.title)
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "In-Person Payments",
        comment: "Title for the In-Person Payments settings screen"
    )
}

struct InPersonPaymentsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            InPersonPaymentsView(viewModel: InPersonPaymentsViewModel(fixedState: .genericError))
        }
    }
}
