import Foundation
import Charts
import UIKit

/// This class is a custom view which is displayed over a chart element (e.g. a Bar) when it is highlighted.
///
/// See: https://github.com/danielgindi/Charts/blob/master/ChartsDemo-iOS/Swift/Components/BalloonMarker.swift
///
class ChartMarker: MarkerImage {
    @objc open var color: UIColor
    @objc open var arrowSize = Constants.arrowSize
    @objc open var font: UIFont
    @objc open var textColor: UIColor
    @objc open var insets: UIEdgeInsets
    @objc open var minimumSize = CGSize()

    private  var label: String?
    private var _labelSize: CGSize = CGSize()
    private var _paragraphStyle: NSMutableParagraphStyle?
    private var _drawAttributes = [NSAttributedString.Key: AnyObject]()

    @objc public init(chartView: ChartViewBase?, color: UIColor, font: UIFont, textColor: UIColor, insets: UIEdgeInsets) {
        self.color = color
        self.font = font
        self.textColor = textColor
        self.insets = insets

        _paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
        _paragraphStyle?.alignment = .center
        super.init()
        self.chartView = chartView
    }

    open override func offsetForDrawing(atPoint point: CGPoint) -> CGPoint {
        var offset = self.offset
        var size = self.size

        if let image = image, size.width == 0.0 {
            size.width = image.size.width
        }

        if let image = image, size.height == 0.0 {
            size.height = image.size.height
        }

        let width = size.width
        let height = size.height
        let padding = Constants.offsetPadding

        var origin = point
        origin.x -= width / 2
        origin.y -= height

        if (origin.x + offset.x) < 0.0 {
            offset.x = -origin.x + padding
        } else if let chart = chartView, (origin.x + width + offset.x) > chart.bounds.size.width {
            offset.x = chart.bounds.size.width - origin.x - width - padding
        }

        if (origin.y + offset.y) < 0 {
            offset.y = height + padding
        } else if let chart = chartView, (origin.y + height + offset.y) > chart.bounds.size.height {
            offset.y = chart.bounds.size.height - origin.y - height - padding
        }

        return CGPoint(x: round(offset.x), y: round(offset.y))
    }

    open override func draw(context: CGContext, point: CGPoint) {
        guard let label = label else {
            return
        }

        let offset = self.offsetForDrawing(atPoint: point)
        let size = self.size

        var rect = CGRect(
            origin: CGPoint(
                x: point.x + offset.x,
                y: point.y + offset.y),
            size: size)
        rect.origin.x -= size.width / 2.0
        rect.origin.y -= size.height
        rect = rect.integral

        context.saveGState()
        context.setFillColor(color.cgColor)

        if offset.y > 0 {
            context.beginPath()
            context.move(to: CGPoint(
                x: rect.origin.x,
                y: rect.origin.y + arrowSize.height))
            context.addLine(to: CGPoint(
                x: rect.origin.x + (rect.size.width - arrowSize.width) / 2.0,
                y: rect.origin.y + arrowSize.height))

            // Arrow vertex
            context.addLine(to: CGPoint(
                x: point.x,
                y: point.y))
            context.addLine(to: CGPoint(
                x: rect.origin.x + (rect.size.width + arrowSize.width) / 2.0,
                y: rect.origin.y + arrowSize.height))
            context.addLine(to: CGPoint(
                x: rect.origin.x + rect.size.width,
                y: rect.origin.y + arrowSize.height))
            context.addLine(to: CGPoint(
                x: rect.origin.x + rect.size.width,
                y: rect.origin.y + rect.size.height))
            context.addLine(to: CGPoint(
                x: rect.origin.x,
                y: rect.origin.y + rect.size.height))
            context.addLine(to: CGPoint(
                x: rect.origin.x,
                y: rect.origin.y + arrowSize.height))
            context.fillPath()
        } else {
            context.beginPath()
            context.move(to: CGPoint(
                x: rect.origin.x,
                y: rect.origin.y))
            context.addLine(to: CGPoint(
                x: rect.origin.x + rect.size.width,
                y: rect.origin.y))
            context.addLine(to: CGPoint(
                x: rect.origin.x + rect.size.width,
                y: rect.origin.y + rect.size.height - arrowSize.height))
            context.addLine(to: CGPoint(
                x: rect.origin.x + (rect.size.width + arrowSize.width) / 2.0,
                y: rect.origin.y + rect.size.height - arrowSize.height))

            //Arrow vertex
            context.addLine(to: CGPoint(
                x: point.x,
                y: point.y))
            context.addLine(to: CGPoint(
                x: rect.origin.x + (rect.size.width - arrowSize.width) / 2.0,
                y: rect.origin.y + rect.size.height - arrowSize.height))
            context.addLine(to: CGPoint(
                x: rect.origin.x,
                y: rect.origin.y + rect.size.height - arrowSize.height))
            context.addLine(to: CGPoint(
                x: rect.origin.x,
                y: rect.origin.y))
            context.fillPath()
        }

        if offset.y > 0 {
            rect.origin.y += self.insets.top + arrowSize.height
        } else {
            rect.origin.y += self.insets.top
        }
        rect.size.height -= self.insets.top + self.insets.bottom
        rect = rect.integral
        UIGraphicsPushContext(context)
        label.draw(in: rect, withAttributes: _drawAttributes)
        UIGraphicsPopContext()
        context.restoreGState()
    }

    open override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        let hintString = entry.accessibilityValue ?? String(entry.y)
        setLabel(hintString)
    }

    @objc open func setLabel(_ newLabel: String) {
        label = newLabel

        _drawAttributes.removeAll()
        _drawAttributes[.font] = self.font
        _drawAttributes[.paragraphStyle] = _paragraphStyle
        _drawAttributes[.foregroundColor] = self.textColor
        _labelSize = label?.size(withAttributes: _drawAttributes) ?? CGSize.zero

        var size = CGSize()
        size.width = _labelSize.width + self.insets.left + self.insets.right
        size.height = _labelSize.height + self.insets.top + self.insets.bottom
        size.width = max(minimumSize.width, size.width)
        size.height = max(minimumSize.height, size.height)
        self.size = size
    }
}


// MARK: - Constants!
//
private extension ChartMarker {
    enum Constants {
        static let arrowSize                = CGSize(width: 20, height: 14)
        static let offsetPadding: CGFloat   = 4.0
    }
}
