import SwiftUI

/// Previews a site in a web view with a border, shadow, and a default height.
struct SitePreviewView: View {
    /// URL of the site.
    let siteURL: URL

    // Tracks the scale of the view due to accessibility changes.
    @ScaledMetric private var scale: CGFloat = 1.0

    var body: some View {
        // Readonly webview for the new site.
        WebView(isPresented: .constant(true), url: siteURL)
            .frame(height: 400 * scale)
            .disabled(true)
            .border(Color(.systemBackground), width: 8)
            .cornerRadius(8)
            .shadow(color: Color(.secondaryLabel), radius: 26)
            .padding(.horizontal, insets: Layout.webviewHorizontalPadding)
    }
}

private extension SitePreviewView {
    enum Layout {
        static let webviewHorizontalPadding: EdgeInsets = .init(top: 0, leading: 44, bottom: 0, trailing: 44)
    }
}

struct SitePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        SitePreviewView(siteURL: URL(string: "https://woocommerce.com")!)
    }
}
