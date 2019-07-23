import UIKit

/// Note on `frameInOrigialImage`: because the frame of the layer could be transformed due to image view content mode resizing, this field keeps the frame in the original image when used to crop the text region.
class TextShapeLayer: CAShapeLayer {
    let color: UIColor
    let frameInOrigialImage: CGRect

    init(color: UIColor, frameInOrigialImage: CGRect) {
        self.color = color
        self.frameInOrigialImage = frameInOrigialImage
        super.init()
        styleLayer(color: color)
    }

    override init(layer: Any) {
        guard let layer = layer as? TextShapeLayer else {
            fatalError()
        }
        self.color = layer.color
        self.frameInOrigialImage = layer.frameInOrigialImage
        super.init(layer: layer)
        styleLayer(color: color)
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
        borderWidth = 3
    }
}
