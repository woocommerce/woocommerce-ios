import UIKit

extension CGRect {
    /// Returns a CGRect that maps the current frame to a target frame that has been scaled to aspect fill in the reference frame.
    /// This assumes the target frame has zero origin and is resized to fill the shortest dimension and centered on the other dimension (the behavior of `resizeAspectFill`).
    ///
    /// - Parameters:
    ///   - referenceFrame: the reference frame for self.
    ///   - targetFrame: the frame that has been scaled to aspect fill in the reference frame.
    func scaling(in referenceFrame: CGRect, to targetFrame: CGRect) -> CGRect {
        // Aspect fill indicates that it is scaled by the maximum factor of the two dimensions.
        let scaleFactor = min(targetFrame.width/referenceFrame.width, targetFrame.height/referenceFrame.height)

        let width = size.width * scaleFactor
        let height = size.height * scaleFactor

        // The position depends on the relative aspect ratio.
        let referenceAspectRatio = referenceFrame.width / referenceFrame.height
        let targetAspectRatio = targetFrame.width / targetFrame.height

        // If the reference frame is shorter than target frame when scaled to fill.
        let x: CGFloat
        let y: CGFloat
        if referenceAspectRatio > targetAspectRatio {
            x = origin.x * scaleFactor
            y = ((targetFrame.height / scaleFactor - referenceFrame.height) / 2.0 + origin.y) * scaleFactor
        } else {
            x = ((targetFrame.width / scaleFactor - referenceFrame.width) / 2.0 + origin.x) * scaleFactor
            y = origin.y * scaleFactor
        }

        return .init(x: x, y: y, width: width, height: height)
    }
}
