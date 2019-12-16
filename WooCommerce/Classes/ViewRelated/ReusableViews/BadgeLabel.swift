import UIKit


final class BadgeLabel: UILabel {
    @IBInspectable var horizontalPadding: CGFloat = 0 {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    @IBInspectable var fillColor: UIColor = .primary

    private let borderWidth: CGFloat
    private let borderColor: UIColor

    // MARK: Initialization

    init(borderWidth: CGFloat, borderColor: UIColor, frame: CGRect) {
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        textAlignment = .center
        layer.masksToBounds = true
        clipsToBounds = true
    }

    // MARK: Padding

    override func drawText(in rect: CGRect) {
        let roundedRect = CGRect(x: rect.origin.x + borderWidth,
                                 y: rect.origin.y + borderWidth,
                                 width: rect.size.width - borderWidth * 2,
                                 height: rect.size.height - borderWidth * 2)

        let path = UIBezierPath(roundedRect: roundedRect, cornerRadius: layer.cornerRadius)
        fillColor.setFill()
        path.fill()

        path.lineWidth = borderWidth
        borderColor.setStroke()
        path.stroke()

        let insets = UIEdgeInsets.init(top: 0, left: horizontalPadding, bottom: 0, right: horizontalPadding)
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        var paddedSize = super.intrinsicContentSize
        paddedSize.width += 2 * horizontalPadding
        return paddedSize
    }

    // MARK: Computed Properties

    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }
}
