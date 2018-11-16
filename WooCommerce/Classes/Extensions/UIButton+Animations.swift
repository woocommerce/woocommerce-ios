import Foundation
import UIKit


// MARK: - UIButton Animations
//
extension UIButton {

    /// Performs an Explosion Animation over an imageView Overlay.
    ///
    func animateImageOverlay(style: OverlayAnimation) {
        guard let overlayView = overlayImageView() else {
            return
        }

        attachOverlayImageView(overlayView: overlayView)

        let animation = style == .explosion ? overlayView.explodeAnimation : overlayView.implodeAnimation
        animation { _ in
            overlayView.removeFromSuperview()
        }
    }

    /// Returns a new Overlay View containing the current state's Asset
    ///
    private func overlayImageView() -> UIView? {
        guard let overlayImage = image(for: state) else {
            return nil
        }

        return UIImageView(image: overlayImage)
    }

    /// Positions a given UIView instance on top of the current UIImageView
    ///
    private func attachOverlayImageView(overlayView: UIView) {
        guard let overlayFrame = imageView?.frame else {
            return
        }

        overlayView.frame = overlayFrame
        addSubview(overlayView)
    }


    // MARK: - Overlay Animations
    //
    enum OverlayAnimation {
        case explosion
        case implosion
    }
}
