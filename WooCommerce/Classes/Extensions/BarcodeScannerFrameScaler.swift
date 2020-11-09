import UIKit

struct BarcodeScannerFrameScaler {
    /// Returns a CGRect that maps the current frame to a target frame that has been scaled to aspect fill in the reference frame.
    /// This assumes the reference and target frame have zero origin, and the target frame is resized to fill the shorter dimension of reference frame and
    /// centered on the other dimension (the behavior of `resizeAspectFill`).
    ///
    /// - Parameters:
    ///   - rect: the rect to be scaled.
    ///   - referenceFrame: the reference frame for `rect`.
    ///   - targetFrame: the frame that has been scaled to aspect fill in the reference frame.
    static func scaling(_ rect: CGRect, in referenceFrame: CGRect, to targetFrame: CGRect) -> CGRect {
        // Aspect fill indicates that it is scaled by the minimum factor of the two dimensions.
        let scaleFactor = min(targetFrame.width/referenceFrame.width, targetFrame.height/referenceFrame.height)

        let width = rect.size.width * scaleFactor
        let height = rect.size.height * scaleFactor

        // The position depends on the relative aspect ratio.
        let referenceAspectRatio = referenceFrame.width / referenceFrame.height
        let targetAspectRatio = targetFrame.width / targetFrame.height

        let x: CGFloat
        let y: CGFloat
        if referenceAspectRatio > targetAspectRatio {
            // If the reference frame is vertically shorter than the target frame when the target frame is scaled to fill the reference frame width.
            // For example, iPhone landscape mode is the reference frame, and the video canvas that has lower aspect ratio.
            x = rect.origin.x * scaleFactor
            y = ((targetFrame.height / scaleFactor - referenceFrame.height) / 2.0 + rect.origin.y) * scaleFactor
        } else {
            // If the reference frame is horizontally shorter than the target frame when the target frame is scaled to fill the reference frame height.
            // For example, iPhone portrait mode is the reference frame, and the video canvas that has higher aspect ratio.
            x = ((targetFrame.width / scaleFactor - referenceFrame.width) / 2.0 + rect.origin.x) * scaleFactor
            y = rect.origin.y * scaleFactor
        }

        return .init(x: x, y: y, width: width, height: height)
    }
}
