import SwiftUI
import WebKit

struct Manual: Identifiable {
    let id: Int
    let name: String
    let urlString: String
}

let bbposChipper2XBT = Manual(
    id: 0,
    name: "bbposChipper2XBT",
    urlString: "https://stripe.com/files/docs/terminal/c2xbt_product_sheet.pdf"
)
let stripeM2 = Manual(
    id: 1,
    name: "stripeM2",
    urlString: "https://stripe.com/files/docs/terminal/m2_product_sheet.pdf"
)
let wisepad3 = Manual(
    id: 2,
    name: "wisepad3",
    urlString: "https://stripe.com/files/docs/terminal/wp3_product_sheet.pdf"
)

let manuals = [bbposChipper2XBT, stripeM2, wisepad3]

struct WebView: UIViewRepresentable {

    var url: URL

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
/// A view to be displayed on Card Reader Manuals screen
///
struct CardReadersView: View {
    var body: some View {
        NavigationView {
            List(manuals, id: \.name) { manual in
                NavigationLink(destination: WebView(url: URL(string: manual.urlString)!) ) {
                    Text(manual.name)
                }
            }
        }.navigationTitle(Localization.navigationTitle)
    }
}

struct CardReadersView_Previews: PreviewProvider {
    static var previews: some View {
        CardReadersView()
    }
}

private extension CardReadersView {
    enum Localization {
        static let navigationTitle = NSLocalizedString( "Card reader manuals",
                                                        comment: "Navigation title at the top of the Card reader manuals screen")
    }
}
