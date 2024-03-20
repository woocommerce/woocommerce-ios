import SwiftUI

struct BlazeAddPaymentMethodWebView: View {
    @ObservedObject private var viewModel: BlazeAddPaymentMethodWebViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: BlazeAddPaymentMethodWebViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationView {
            Group {
                AuthenticatedWebView(isPresented: .constant(true),
                                     url: viewModel.addPaymentMethodURL,
                                     urlToTriggerExit: viewModel.addPaymentSuccessURL) { _ in
                    viewModel.didAddNewPaymentMethod()
                    dismiss()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancelButton) {
                        dismiss()
                    }
                }
            }
            .navigationTitle(Localization.navigationBarTitle)
            .wooNavigationBarStyle()
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.onAppear()
        }
        .notice($viewModel.notice)
    }
}

private extension BlazeAddPaymentMethodWebView {
    enum Localization {
        static let navigationBarTitle = NSLocalizedString(
            "blazeAddPaymentWebView.navigationBarTitle",
            value: "Payment Method",
            comment: "Navigation bar title in the Blaze Add Payment Method screen"
        )
        static let cancelButton = NSLocalizedString(
            "blazeAddPaymentWebView.cancelButton",
            value: "Cancel",
            comment: "Title of the button to dismiss the Blaze Add Payment Method screen"
        )
    }
}

struct BlazeAddPaymentWebView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = BlazeAddPaymentMethodWebViewModel(siteID: 123,
                                                          completion: { })

        BlazeAddPaymentMethodWebView(viewModel: viewModel)
    }
}
