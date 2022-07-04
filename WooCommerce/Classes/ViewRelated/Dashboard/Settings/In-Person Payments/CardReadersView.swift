import SwiftUI
import WebKit

struct Manual: Identifiable {
    let id: Int
    let name: String
    let urlString: String
}

let bbposChipper2XBT = Manual(
    id: 0,
    name: "BBPOS Chipper 2X BT",
    urlString: "https://stripe.com/files/docs/terminal/c2xbt_product_sheet.pdf"
)
let stripeM2 = Manual(
    id: 1,
    name: "Stripe Reader M2",
    urlString: "https://stripe.com/files/docs/terminal/m2_product_sheet.pdf"
)
let wisepad3 = Manual(
    id: 2,
    name: "Wisepad 3",
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

struct CardReaderViewDetail: View {
    var choice: Manual

    var body: some View {
        NavigationLink(destination: WebView(url: URL(string: choice.urlString)!)) {
            // TODO: Needs refactor
            return WebView(url: URL(string: choice.urlString)!)
        }
    }
}
/// A view to be displayed on Card Reader Manuals screen
///
struct CardReadersView: View {
    var body: some View {
        NavigationView {
            List(manuals, id: \.name) { manual in
                VStack {
                    NavigationLink(destination: CardReaderViewDetail(choice: manual)) {
                        // Temporary Image placeholder using SwiftUI wrapper
                        Image(uiImage: .cardReaderManualIcon)
                        Text(manual.name)
                    }
                    .navigationBarTitle(Localization.navigationTitle, displayMode: .inline)
                }
            }
        }
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
