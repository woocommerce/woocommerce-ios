import UIKit

/// An animatable circular spinner.
///
final class CircleSpinnerView: UIView {

    // MARK: Configurable properties

    var color: UIColor = .brand {
        didSet {
            layer.strokeColor = color.cgColor
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
    }

    // MARK: Animation step

    /// Describes an animation step in a sequence.
    struct AnimationStep {
        /// How many seconds since the previous animation step.
        let secondsSincePreviousAnimation: CFTimeInterval

        /// How many degrees to rotate, in terms of 360 degrees. For example, a full rotation is 1.0.
        let rotationDegrees: CGFloat

        init(secondsSincePriorPose: CFTimeInterval, rotationDegrees: CGFloat) {
            self.secondsSincePreviousAnimation = secondsSincePriorPose
            self.rotationDegrees = rotationDegrees
        }
    }

    private let animationSteps: [AnimationStep] = [
        AnimationStep(secondsSincePriorPose: 0, rotationDegrees: 0),
        AnimationStep(secondsSincePriorPose: 1, rotationDegrees: 1)
    ]

    // MARK: Set up the view to have a CAShapeLayer

    override class var layerClass: AnyClass {
        return CAShapeLayer.self
    }

    override var layer: CAShapeLayer {
        return super.layer as! CAShapeLayer
    }

    // MARK: Overrides

    override func layoutSubviews() {
        super.layoutSubviews()
        setPath()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        animate()
    }

    // MARK: Public interface

    func animate() {
        let totalAnimationDuration = animationSteps.sum(\.secondsSincePreviousAnimation)
        let rotations = animationSteps.map({ $0.rotationDegrees * 2 * .pi })

        // Calculates the time (in terms of duration fraction) for each animation step.
        var time: CFTimeInterval = 0
        var times = [CFTimeInterval]()
        for animationStep in animationSteps {
            time += animationStep.secondsSincePreviousAnimation
            times.append(time / totalAnimationDuration)
        }

        animateKeyPath(keyPath: "transform.rotation", duration: totalAnimationDuration, times: times, values: rotations)
    }
}

// MARK: Configurations
//
private extension CircleSpinnerView {
    func configureView() {
        backgroundColor = .clear
        layer.fillColor = nil
        layer.lineWidth = Constants.lineWidth
        layer.strokeEnd = Constants.strokeEnd
    }
}

private extension CircleSpinnerView {
    /// Draws a circle given the layer line width.
    ///
    func setPath() {
        layer.path = UIBezierPath(ovalIn: bounds.insetBy(dx: layer.lineWidth / 2, dy: layer.lineWidth / 2)).cgPath
    }

    /// Animates a key path for a duration with a sequence of values at different time.
    ///
    /// - Parameters:
    ///   - keyPath: an animatable key path of `CAShapeLayer`.
    ///   - duration: for how long the whole animation sequence takes.
    ///   - times: an array of time when each corresponding value is set.
    ///   - values: an array of values to be applied at each corresponding time.
    ///
    func animateKeyPath(keyPath: String, duration: CFTimeInterval, times: [CFTimeInterval], values: [CGFloat]) {
        let animation = CAKeyframeAnimation(keyPath: keyPath)
        animation.keyTimes = times as [NSNumber]?
        animation.values = values
        animation.calculationMode = .linear
        animation.duration = duration
        animation.repeatCount = Float.infinity
        layer.add(animation, forKey: animation.keyPath)
    }
}

private extension CircleSpinnerView {
    enum Constants {
        /// The thickness of the circle.
        static let lineWidth: CGFloat = 4

        /// The percentage of circle to be shown, from 0 (none) to 1 (full circle).
        static let strokeEnd: CGFloat = 0.75
    }
}
