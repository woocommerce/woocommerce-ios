import SwiftUI

/// A banner warning about currency mismatch between site and user account
struct CurrencyMismatchBanner: View {
    let siteCurrency: String
    let accountCurrency: String
    
    /// Closure invoked when the dismiss button is tapped
    var dismissAction: () -> Void = {}
    
    // Tracks the scale of the view due to accessibility changes
    @ScaledMetric private var scale: CGFloat = 1.0
    
    var body: some View {
        Group {
            HStack(alignment: .top, spacing: Layout.horizontalSpacing) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                    .frame(width: Layout.iconDimension * scale, height: Layout.iconDimension * scale)
                    .foregroundColor(Color(.wooOrange))
                VStack(alignment: .leading, spacing: Layout.verticalTextSpacing) {
                    Text(Localization.title)
                        .fontWeight(.semibold)
                        .bodyStyle()
                    Text(String(format: Localization.message, siteCurrency, accountCurrency))
                        .bodyStyle()
                        .foregroundColor(Color(.text.secondary))
                }
                Spacer()
                Button(action: dismissAction) {
                    Image(systemName: "xmark")
                        .foregroundColor(Color(.text.secondary))
                }
            }
            .padding(insets: Layout.padding)
        }
        .background(Color(.bannerBackground))
        .fixedSize(horizontal: false, vertical: true)
        .contentShape(Rectangle())
    }
}

private extension CurrencyMismatchBanner {
    enum Localization {
        static let title = NSLocalizedString(
            "currencyMismatchBanner.title",
            value: "Currency mismatch detected",
            comment: "Title of the currency mismatch warning banner on the dashboard."
        )
        static let message = NSLocalizedString(
            "currencyMismatchBanner.message",
            value: "Your site uses %1$@ but your payment account uses %2$@. This may cause issues with payments. Please update your account currency to match your site's currency in your payment gateway settings.",
            comment: "Message of the currency mismatch warning banner. %1$@ is the site currency code (e.g. USD), %2$@ is the account currency code (e.g. GBP)."
        )
    }
    
    enum Layout {
        static let padding = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        static let iconDimension = CGFloat(20)
        static let horizontalSpacing = CGFloat(12)
        static let verticalTextSpacing = CGFloat(8)
    }
}

struct CurrencyMismatchBanner_Previews: PreviewProvider {
    static var previews: some View {
        CurrencyMismatchBanner(siteCurrency: "USD", accountCurrency: "GBP")
            .preferredColorScheme(.light)
            .previewLayout(.sizeThatFits)
        CurrencyMismatchBanner(siteCurrency: "USD", accountCurrency: "GBP")
            .preferredColorScheme(.dark)
            .previewLayout(.sizeThatFits)
        CurrencyMismatchBanner(siteCurrency: "EUR", accountCurrency: "CAD")
            .preferredColorScheme(.light)
            .environment(\.sizeCategory, .extraExtraExtraLarge)
            .previewLayout(.sizeThatFits)
    }
}
