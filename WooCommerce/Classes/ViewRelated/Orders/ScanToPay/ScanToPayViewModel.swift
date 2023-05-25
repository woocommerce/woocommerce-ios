import Foundation
import UIKit
import WooFoundation

struct ScanToPayViewModel {
    private let paymentURL: URL?

    init(paymentURL: URL?) {
        self.paymentURL = paymentURL
    }

    func generateQRCodeImage() -> UIImage? {
        guard let logoImage = UIImage
            .wooLogoImage()?
            .withBackground(color: .black) else {
            return paymentURL?.generateQRCode()
        }

        return paymentURL?.generateQRCode(combinedWith: logoImage)
    }
}
