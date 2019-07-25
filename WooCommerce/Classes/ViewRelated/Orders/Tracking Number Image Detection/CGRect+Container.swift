import UIKit

extension CGRect {
    // TODO: unit tests.
    func calculateFrame(originalParentSize: CGSize, toFitIn containerSize: CGSize) -> CGRect {
        let scale = min(containerSize.width / originalParentSize.width, containerSize.height / originalParentSize.height)
        let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)

        // Scale rect with image.
        let newSize = size.applying(scaleTransform)

        // Offset rect with image.
        let newParentSize = originalParentSize.applying(scaleTransform)
        let offsetTransform = CGAffineTransform(translationX: (containerSize.width - newParentSize.width) / 2.0,
                                                y: (containerSize.height - newParentSize.height) / 2.0)
        let newOrigin = origin
            .applying(scaleTransform)
            .applying(offsetTransform)
        let frame = CGRect(origin: newOrigin, size: newSize)
        return frame
    }
}
