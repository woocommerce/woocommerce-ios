/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implements a timer UI.
*/

import Combine
import Foundation
import SwiftUI

/// This view displays a darkened circle that fills with a brighter arc based on the time remaining on a `Timer`.
struct TimerView: View {
    @ObservedObject var model: CameraViewModel

    private let fillColor: Color = Color.clear
    private let unprogressedColor: Color = Color(red: 0.5, green: 0.5, blue: 0.5)
    private let progressedColor: Color = .white

    private var timerDiameter: CGFloat = 50
    private var timerBarWidth: CGFloat = 5

    init(model: CameraViewModel, diameter: CGFloat = 50, barWidth: CGFloat = 5) {
        self.model = model
        self.timerDiameter = diameter
        self.timerBarWidth = barWidth
    }

    var body: some View {
        ZStack {

            Circle()
                .fill(fillColor)
                .frame(width: timerDiameter, height: timerDiameter)
                .overlay(
                    Circle().stroke(unprogressedColor, lineWidth: timerBarWidth)
                )
            Circle()
                .fill(Color.clear)
                .frame(width: timerDiameter, height: timerDiameter)
                .overlay(
                    Circle()
                        .trim(from: 0,
                              to: CGFloat(1.0 -
                                            (model.timeUntilCaptureSecs / model.autoCaptureIntervalSecs)))
                        .stroke(style: StrokeStyle(lineWidth: timerBarWidth,
                                                   lineCap: .round,
                                                   lineJoin: .round))
                        .foregroundColor(progressedColor))
        }
    }
}
