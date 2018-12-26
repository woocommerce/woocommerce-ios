import Foundation
import UIKit


/// BordersView: Convenience UIView Subclass with the ability to render borders
///
class BordersView: UIView {

    /// Indicates if the Left Border should be visible
    ///
    @objc var leftVisible = false {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Left Border's Color
    ///
    @objc var leftColor = UIColor.clear {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Left Border's Height (in Pixels)
    ///
    @objc var leftWidthInPoints = CGFloat(3) {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Indicates if the Top Border should be visible
    ///
    @objc var topVisible = false {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Top Border's Color
    ///
    @objc var topColor = UIColor.lightGray {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Top Border's Height (in Pixels)
    ///
    @objc var topHeightInPixels = CGFloat(1) {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Top Border Insets
    ///
    @objc var topInsets = UIEdgeInsets.zero {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Indicates if the Bottom Border should be visible
    ///
    @objc var bottomVisible = false {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Bottom Border's Color
    ///
    @objc var bottomColor = UIColor.lightGray {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Bottom Border's Height (in Pixels)
    ///
    @objc var bottomHeightInPixels = CGFloat(1) {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Bottom Border Insets
    ///
    @objc var bottomInsets = UIEdgeInsets.zero {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Overriden Frame Property!
    ///
    override var frame: CGRect {
        didSet {
            setNeedsDisplay()
        }
    }



    // MARK: - UIView methods

    convenience init() {
        self.init(frame: .zero)
    }

    required override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        let scale = UIScreen.main.scale
        context.clear(rect)
        context.setShouldAntialias(false)

        // Background
        if backgroundColor != nil {
            backgroundColor?.setFill()
            context.fill(rect)
        }

        // Left Separator
        if leftVisible {
            leftColor.setStroke()
            context.setLineWidth(leftWidthInPoints * scale)
            context.move(to: CGPoint(x: bounds.minX, y: bounds.minY))
            context.addLine(to: CGPoint(x: bounds.minX, y: bounds.maxY))
            context.strokePath()
        }

        // Top Separator
        if topVisible {
            topColor.setStroke()
            let lineWidth = topHeightInPixels / scale
            context.setLineWidth(lineWidth)
            context.move(to: CGPoint(x: topInsets.left, y: lineWidth))
            context.addLine(to: CGPoint(x: bounds.maxX - topInsets.right, y: lineWidth))
            context.strokePath()
        }

        // Bottom Separator
        if bottomVisible {
            bottomColor.setStroke()
            context.setLineWidth(bottomHeightInPixels / scale)
            context.move(to: CGPoint(x: bottomInsets.left, y: bounds.height))
            context.addLine(to: CGPoint(x: bounds.maxX - bottomInsets.right, y: bounds.height))
            context.strokePath()
        }
    }

    private func setupView() {
        backgroundColor = .clear

        // Make sure this is re-drawn if the bounds change!
        layer.needsDisplayOnBoundsChange = true
    }
}
