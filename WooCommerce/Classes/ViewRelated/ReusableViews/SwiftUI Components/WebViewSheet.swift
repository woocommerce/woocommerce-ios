import SwiftUI

struct WebViewSheetViewModel {
    let url: URL
    let navigationTitle: String
    let authenticated: Bool
}

struct WebViewSheet: View {
    let viewModel: WebViewSheetViewModel

    let done: () -> Void

    var body: some View {
        WooNavigationSheet(viewModel: .init(navigationTitle: viewModel.navigationTitle,
                                            done: done)) {
            switch viewModel.authenticated {
            case true:
                AuthenticatedWebView(isPresented: .constant(true),
                                     url: viewModel.url)
            case false:
                WebView(isPresented: .constant(true),
                            url: viewModel.url)
            }
        }
    }
}

struct WebViewSheet_Previews: PreviewProvider {
    static var previews: some View {
        WebViewSheet(
            viewModel: WebViewSheetViewModel.init(
                url: URL(string: "https://woocommerce.com")!,
                navigationTitle: "WooCommerce.com",
                authenticated: true),
            done: { })
    }
}
