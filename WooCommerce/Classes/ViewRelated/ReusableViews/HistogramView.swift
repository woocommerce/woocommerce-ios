//
//  HistogramView.swift
//  WooCommerce
//
//  Created by Allen Snook on 3/12/21.
//  Copyright © 2021 Automattic. All rights reserved.
//

import UIKit

class HistogramView: UIView {

    private var data = [Int]()

    public func setData(data: [Int]) {
        self.data = data
    }

    private func colorForBin(bin: Int) -> CGColor {
        // TODO - allow this to be configured externally
        if bin < 3 {
            return CGColor(red: 0, green: 1, blue: 0, alpha: 0.8)
        }

        if bin < 5 {
            return CGColor(red: 1, green: 0.7, blue: 0, alpha: 0.8)
        }

        return CGColor(red: 1, green: 0, blue: 0, alpha: 0.8)
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        context.setFillColor(UIColor.white.cgColor)
        context.fill(bounds)

        if data.count == 0 {
            // TODO - show a No Data Available message
            return
        }

        let max = data.max() ?? 0
        if max < 1 {
            // TODO -show a No Data Available message
            return
        }

        let graphLeftMargin: CGFloat = 20
        let graphRightMargin: CGFloat = 20
        let graphTopMargin: CGFloat = 10
        let graphBottomMargin: CGFloat = 10

        let xAxisTitleHeight: CGFloat = 20
        let xAxisValueHeight: CGFloat = 20

        let plotAreaWidth = bounds.width - graphLeftMargin - graphRightMargin
        let plotAreaHeight = bounds.height - graphTopMargin - graphBottomMargin - xAxisTitleHeight - xAxisValueHeight

        let plotAreaX0 = graphLeftMargin
        let plotAreaY0 = graphTopMargin + plotAreaHeight

        var rightMostBin = 0
        for bin in 0..<data.count {
            if data[bin] > 0 {
                rightMostBin = bin
            }
        }

        let binWidth = plotAreaWidth / CGFloat(rightMostBin + 1)
        let barWidth = binWidth * 0.8
        let binScale = plotAreaHeight / CGFloat(max)

        for bin in 0...rightMostBin {
            let binHeight = binScale * CGFloat(data[bin])
            let x = plotAreaX0 + CGFloat(bin) * binWidth + (binWidth - barWidth) / 2
            let y = plotAreaY0 - binHeight
            let rectangle = CGRect(x: x, y: y, width: barWidth, height: binHeight)
            context.setFillColor(colorForBin(bin: bin))
            context.setStrokeColor(colorForBin(bin: bin))
            context.fill(rectangle)
        }

        // Common Text Attributes
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attrs = [NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-CondensedBold", size: 14)!, NSAttributedString.Key.paragraphStyle: paragraphStyle]

        // X-Axis Title
        let xAxisTitleRect = CGRect(
            x: graphLeftMargin,
            y: bounds.height - xAxisTitleHeight,
            width: plotAreaWidth,
            height: xAxisTitleHeight
        )
        let xAxisTitleText = "response time, seconds" // TODO localize, pass in
        xAxisTitleText.draw(in: xAxisTitleRect, withAttributes: attrs)

        // First bin label
        let firstBinRect = CGRect(
            x: graphLeftMargin,
            y: bounds.height - xAxisTitleHeight - xAxisValueHeight,
            width: binWidth,
            height: xAxisValueHeight
        )
        let firstBinText = "1" // TODO localize
        firstBinText.draw(in: firstBinRect, withAttributes: attrs)

        // Rightmost bin label
        let rightMostBinRect = CGRect(
            x: bounds.width - graphRightMargin - binWidth,
            y: bounds.height - xAxisTitleHeight - xAxisValueHeight,
            width: binWidth,
            height: xAxisValueHeight
        )
        let rightMostBinText = "\(rightMostBin)+"
        rightMostBinText.draw(in: rightMostBinRect, withAttributes: attrs)
    }
}
