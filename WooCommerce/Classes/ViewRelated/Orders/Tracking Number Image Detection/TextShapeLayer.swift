import UIKit

class TextShapeLayer: CAShapeLayer {
    init(color: UIColor) {
        super.init()
        styleLayer(color: color)
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension TextShapeLayer {
    func styleLayer(color: UIColor) {
        // Configure layer's appearance.
        fillColor = nil // No fill to show boxed object
        shadowOpacity = 0
        shadowRadius = 0
        borderWidth = 2

        // Vary the line color according to input.
        borderColor = color.cgColor
    }
}
