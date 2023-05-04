import SwiftUI
import Foundation
import CoreImage.CIFilterBuiltins

struct SharePaymentLinkView: View {
    let url: URL
    let formattedTotal: String
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()

    @State var sharingPaymentLink = false

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Spacer()
            Text("Scan to Pay")
                .largeTitleStyle()
            Text(formattedTotal)
                .titleStyle()
            Image(uiImage: generateQRCode(from: url.absoluteString))
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
            Spacer()
            Button(Localization.link) {
                sharingPaymentLink = true
            }
        }
        .shareSheet(isPresented: $sharingPaymentLink) {
            // If paymentLink is available it already contains a valid URL.
            // CompactMap is required due to Swift URL APIs.
            ShareSheet(activityItems: [url].compactMap { $0 } ) { _, completed, _, _ in
                if completed {
                    //dismiss()
                    //viewModel.performLinkSharedTasks()
                }
            }
        }
    }

    func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}

// MARK: Constants
extension SharePaymentLinkView {
    enum Localization {
        static let link = NSLocalizedString("Share Payment Link", comment: "Payment Link method title on the select payment method screen")

    }

    enum Accessibility {
        static let headerLabel = "payment-methods-header-label"
        static let cashMethod = "payment-methods-view-cash-row"
        static let cardMethod = "payment-methods-view-card-row"
        static let tapToPayMethod = "payment-methods-view-tap-to-pay-row"
        static let paymentLink = "payment-methods-view-payment-link-row"
    }

}
