import CoreImage.CIFilterBuiltins

extension CIImage {
    /// Combines the current image with the given image centered.
    ///
    func combined(with image: CIImage) -> CIImage? {
        guard let combinedFilter = CIFilter(name: "CISourceOverCompositing") else {
            return nil
        }

        let centerTransform = CGAffineTransform(translationX: extent.midX - (image.extent.size.width / 2), y: extent.midY - (image.extent.size.height / 2))
        combinedFilter.setValue(image.transformed(by: centerTransform), forKey: "inputImage")
        combinedFilter.setValue(self, forKey: "inputBackgroundImage")

        return combinedFilter.outputImage
    }
}
