import Charts
import UIKit

/// Circle marker which is shown on the highlighted point in the line chart.
final class StoreStatsChartCircleMarker: MarkerImage {
    override func draw(context: CGContext, point: CGPoint) {
        let radius = Constants.radius
        let circleRect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
        // Draws a circle with fill color.
        context.setFillColor(Constants.fillColor.cgColor)
        context.fillEllipse(in: circleRect)

        // Draws a circular border with stroke color and shadow.
        context.setLineWidth(Constants.borderWidth)
        context.addEllipse(in: circleRect)
        context.setStrokeColor(Constants.borderColor.cgColor)
        context.setShadow(offset: .init(width: 0, height: 4), blur: 4, color: Constants.shadowColor.cgColor)
        context.drawPath(using: .fillStroke)

        context.restoreGState()
    }
}

private extension StoreStatsChartCircleMarker {
    enum Constants {
        static let radius: CGFloat = 4.5
        static let fillColor: UIColor = .accent
        static let borderWidth: CGFloat = 1.5
        static let borderColor: UIColor = .white
        static let shadowColor: UIColor =
            UIColor(light: UIColor(red: 137/256, green: 137/256, blue: 137/256, alpha: 0.25),
                    dark: UIColor(red: 0, green: 0, blue: 0, alpha: 0.25))
    }
}
