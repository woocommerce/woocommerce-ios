import UIKit

class DotView: UIView {

    private var borderWidth = CGFloat(1) // Border line width defaults to 1

    private let color: UIColor

    /// Designated Initializer
    ///
    init(frame: CGRect, color: UIColor, borderWidth: CGFloat) {
        self.color = color
        super.init(frame: frame)
        self.borderWidth = borderWidth
        setupSubviews()
    }

    /// Required Initializer
    ///
    required init?(coder aDecoder: NSCoder) {
        color = UIColor.primary

        super.init(coder: aDecoder)
        setupSubviews()
    }

    private func setupSubviews() {
        backgroundColor = .clear
    }

    override func draw(_ rect: CGRect) {
        let path = UIBezierPath(ovalIn: CGRect(x: rect.origin.x + borderWidth,
                                               y: rect.origin.y + borderWidth,
                                               width: rect.size.width - borderWidth * 2,
                                               height: rect.size.height - borderWidth * 2))
        color.setFill()
        path.fill()

        path.lineWidth = borderWidth
        UIColor.basicBackground.setStroke()
        path.stroke()
    }
}
