import Foundation
import UIKit

public extension URL {
    /// Returns a black and white QR UIImage code for this URL.
    ///
    func generateQRCode() -> UIImage? {
        guard let outputImage = generateQRCodeCIImage(),
              let cgImage = CIContext().createCGImage(outputImage, from: outputImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }


    /// Returns a black and white QR code for this URL, adding the passed image centered.
    ///
    func generateQRCode(combinedWith image: UIImage) -> UIImage? {
        guard let outputImage = generateQRCodeCIImage(),
              let cgLogoImage = image.cgImage,
              let combinedImage = outputImage.combined(with: CIImage(cgImage: cgLogoImage)),
              let cgImage = CIContext().createCGImage(combinedImage, from: combinedImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    /// Returns a black and white QR CIImage code for this URL.
    ///
    private func generateQRCodeCIImage() -> CIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(absoluteString.utf8)

        let qrTransform = CGAffineTransform(scaleX: 12, y: 12)
        return filter.outputImage?.transformed(by: qrTransform)
    }
}
