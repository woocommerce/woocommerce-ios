import UIKit

// Imported from WordPress iOS
// https://github.com/wordpress-mobile/WordPress-iOS/blob/trunk/WordPress/Classes/ViewRelated/Feature%20Highlight/TooltipPresenter.swift

/// A helper class for presentation of the Tooltip in respect to a `targetView`.
/// Must be retained to respond to device orientation and size category changes.
final class TooltipPresenter {
    private enum Constants {
        static let verticalTooltipDistanceToFocus: CGFloat = 0
        static let horizontalBufferMargin: CGFloat = 20
        static let tooltipTopConstraintAnimationOffset: CGFloat = 8
        static let tooltipAnimationDuration: TimeInterval = 0.2
    }

    enum TooltipVerticalPosition {
        case auto
        case above
        case below
    }

    enum Target {
        case view(UIView)
        case point((() -> CGPoint))
    }

    private let containerView: UIView
    private var primaryTooltipAction: (() -> Void)?
    private var secondaryTooltipAction: (() -> Void)?
    private var tooltipTopConstraint: NSLayoutConstraint?
    private let target: Target

    private var targetMidX: CGFloat {
        switch target {
        case .view(let targetView):
            return targetView.frame.midX
        case .point(let targetPoint):
            return targetPoint().x
        }
    }

    private var targetMinY: CGFloat {
        switch target {
        case .view(let targetView):
            return targetView.frame.minY
        case .point(let targetPoint):
            return targetPoint().y
        }
    }


    private(set) var tooltip: Tooltip
    var tooltipVerticalPosition: TooltipVerticalPosition = .auto

    private var totalVerticalBuffer: CGFloat {
        Constants.verticalTooltipDistanceToFocus
        + Constants.tooltipTopConstraintAnimationOffset
    }

    private var previousDeviceOrientation: UIDeviceOrientation?

    init(containerView: UIView,
         tooltip: Tooltip,
         target: Target,
         primaryTooltipAction: (() -> Void)? = nil,
         secondaryTooltipAction: (() -> Void)? = nil
    ) {
        self.containerView = containerView
        self.tooltip = tooltip
        self.primaryTooltipAction = primaryTooltipAction
        self.secondaryTooltipAction = secondaryTooltipAction
        self.target = target

        configureDismissal()

        previousDeviceOrientation = UIDevice.current.orientation
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(resetTooltipAndShow),
            name: UIContentSizeCategory.didChangeNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didDeviceOrientationChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }

    func showTooltip() {
        tooltip.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(tooltip)
        self.tooltip.alpha = 0
        tooltip.addArrowHead(toXPosition: arrowOffsetX(), arrowPosition: tooltipOrientation())
        setUpTooltipConstraints()

        containerView.layoutIfNeeded()
        animateTooltipIn()
    }

    func dismissTooltip() {
        UIView.animate(
            withDuration: Constants.tooltipAnimationDuration,
            delay: 0,
            options: .curveEaseOut
        ) {
            guard let tooltipTopConstraint = self.tooltipTopConstraint else {
                return
            }

            self.tooltip.alpha = 0
            tooltipTopConstraint.constant += Constants.tooltipTopConstraintAnimationOffset
            self.containerView.layoutIfNeeded()
        } completion: { isSuccess in
            self.primaryTooltipAction?()
            self.removeTooltip()
        }
    }

    // Silently removes the tooltip without firing the `primaryTooltipAction` callback
    //
    func removeTooltip() {
        tooltip.removeFromSuperview()
        NotificationCenter.default.removeObserver(self)
    }

    private func animateTooltipIn() {
        UIView.animate(
            withDuration: Constants.tooltipAnimationDuration,
            delay: 0,
            options: .curveEaseOut
        ) {
            guard let tooltipTopConstraint = self.tooltipTopConstraint else {
                return
            }

            self.tooltip.alpha = 1
            tooltipTopConstraint.constant -= Constants.tooltipTopConstraintAnimationOffset

            self.containerView.layoutIfNeeded()
        }
    }

    private func configureDismissal() {
        tooltip.dismissalAction = dismissTooltip
    }

    private func setUpTooltipConstraints() {
        var tooltipConstraints = [
            tooltip.centerXAnchor.constraint(equalTo: containerView.centerXAnchor, constant: extraArrowOffsetX())
        ]

        let tooltipTopConstraint: NSLayoutConstraint
        switch target {
        case .view(let targetView):
            switch tooltipOrientation() {
            case .bottom:
                tooltipTopConstraint = targetView.topAnchor.constraint(
                    equalTo: tooltip.bottomAnchor,
                    constant: totalVerticalBuffer
                )
            case .top:
                tooltipTopConstraint = tooltip.topAnchor.constraint(
                    equalTo: targetView.bottomAnchor,
                    constant: totalVerticalBuffer
                )
            }
        case .point(let targetPoint):
            switch tooltipOrientation() {
            case .bottom:
                tooltipTopConstraint = tooltip.bottomAnchor.constraint(
                    equalTo: containerView.topAnchor,
                    constant: targetPoint().y + totalVerticalBuffer)
            case .top:
                tooltipTopConstraint = tooltip.topAnchor.constraint(
                    equalTo: containerView.topAnchor,
                    constant: targetPoint().y + totalVerticalBuffer)
            }
        }
        tooltipConstraints.append(tooltipTopConstraint)
        self.tooltipTopConstraint = tooltipTopConstraint

        NSLayoutConstraint.activate(tooltipConstraints)
    }

    /// `orientationDidChangeNotification` is published when the device is at `faceUp` or `faceDown`
    ///  states too. The sizing won't be affected in these cases so no need to reset the tooltip. Here we filter out changes
    ///  to and from `faceUp` & `faceDown`.
    @objc private func didDeviceOrientationChange() {
        guard let previousDeviceOrientation = previousDeviceOrientation else {
            return
        }

        self.previousDeviceOrientation = UIDevice.current.orientation

        switch (previousDeviceOrientation, UIDevice.current.orientation) {
        case (_, .faceUp), (_, .faceDown), (.faceUp, _), (.faceDown, _):
            return
        default:
            resetTooltipAndShow()
        }
    }

    @objc private func resetTooltipAndShow() {
        UIView.animate(
            withDuration: Constants.tooltipAnimationDuration,
            delay: 0,
            options: .curveEaseOut
        ) {
            guard let tooltipTopConstraint = self.tooltipTopConstraint else {
                return
            }

            self.tooltip.alpha = 0
            tooltipTopConstraint.constant += Constants.tooltipTopConstraintAnimationOffset
            self.containerView.layoutIfNeeded()
        } completion: { isSuccess in
            self.tooltip.removeFromSuperview()
            self.tooltip = self.tooltip.copy(containerWidth: self.containerView.bounds.width)
            self.showTooltip()
        }
    }

    /// Calculates where the arrow needs to place in the borders of the tooltip.
    /// This depends on the position of the target relative to `tooltip`.
    private func arrowOffsetX() -> CGFloat {
        targetMidX - ((containerView.bounds.width - tooltip.size().width) / 2) - extraArrowOffsetX()
    }

    /// If the tooltip is always vertically centered, tooltip's width may not be big enough to reach to the target
    /// If `xxxxxxxx` is the Tooltip and `oo` is the target:
    /// |                                               |
    /// |                xxxxxxxx                 |
    /// |                                    oo       |
    /// The tooltip needs an extra X offset to be aligned with target so that tooltip arrow points to the correct position.
    /// Here the tooltip is pushed to the right so the arrow is pointing at the target
    /// |                                               |
    /// |                           xxxxxxxx     |
    /// |                                    oo       |
    /// It would be retracted instead if the target was at the left of the screen.
    ///
    private func extraArrowOffsetX() -> CGFloat {
        let tooltipWidth = tooltip.size().width
        let extraPushOffset = max(
            (targetMidX + Constants.horizontalBufferMargin) - (containerView.safeAreaLayoutGuide.layoutFrame.midX + tooltipWidth / 2),
            0
        )

        if extraPushOffset > 0 {
            return extraPushOffset
        }

        let extraRetractOffset = min(
            (targetMidX - Constants.horizontalBufferMargin) - (containerView.safeAreaLayoutGuide.layoutFrame.midX - tooltipWidth / 2),
            0
        )

        return extraRetractOffset
    }


    private func tooltipOrientation() -> Tooltip.ArrowPosition {
        switch tooltipVerticalPosition {
        case .auto:
            if containerView.frame.midY < targetMinY {
                return .bottom
            }
            return .top
        case .above:
            return .bottom
        case .below:
            return .top
        }
    }
}
