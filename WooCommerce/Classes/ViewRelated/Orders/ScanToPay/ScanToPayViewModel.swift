import Foundation
import CoreImage.CIFilterBuiltins
import UIKit

struct ScanToPayViewModel {
    private let paymentURL: URL?

    init(paymentURL: URL?) {
        self.paymentURL = paymentURL
    }

    func generateQRCodeImage() -> UIImage? {
        guard let paymentURLString = paymentURL?.absoluteString else {
            return nil
        }

        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(paymentURLString.utf8)

        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
