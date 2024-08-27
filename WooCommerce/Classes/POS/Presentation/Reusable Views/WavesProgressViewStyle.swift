import SwiftUI

struct WaveProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        WaveProgressView(configuration: configuration)
    }
}

private struct WaveProgressView: View {
    let configuration: ProgressViewStyleConfiguration
    private let animationDuration: Double = 0.5
    private let radii: [CGFloat] = [40.0, 70.0, 100.0]
    private let inactiveInset: CGFloat = 0.025

    @State private var activeArcIndex: Int = 0

    private var arcCount: Int {
        radii.count
    }

    private var xOffset: CGFloat {
        guard let lastRadius = radii.last,
              let firstRadius = radii.first,
              lastRadius > firstRadius else {
            return 0
        }
        let centreOfWaves = (lastRadius - firstRadius) / 2
        return -((firstRadius + centreOfWaves) / 2)
    }

    var body: some View {
        ZStack {
            ForEach(0..<arcCount, id: \.self) { index in
                let isActive = index == activeArcIndex
                let radius = radii[index]

                ArcShape(startAngle: .degrees(333),
                         endAngle: .degrees(27))
                .trim(from: isActive ? 0.0 : 0 + inactiveInset,
                      to: isActive ? 1.0 : 1 - inactiveInset)
                .stroke(isActive ? Color(.wooCommercePurple(.shade60)) : Color(.wooCommercePurple(.shade40)),
                        lineWidth: isActive ? 10 : 7)
                .frame(width: radius, height: radius)
                .animation(.easeInOut(duration: animationDuration),
                           value: activeArcIndex)
            }
        }
        .offset(x: xOffset)
        .frame(width: 130, height: 115)
        .background() {
            Color(.wooCommercePurple(.shade20))
                .clipShape(RoundedRectangle(cornerRadius: 13))
        }
        .onAppear {
            startAnimating()
        }
        .accessibilityLabel(Localization.accessibilityLabel)
    }

    private func startAnimating() {
        Timer.scheduledTimer(withTimeInterval: animationDuration, repeats: true) { _ in
            withAnimation {
                activeArcIndex = (activeArcIndex + 1) % arcCount
            }
        }
    }
}

private extension WaveProgressView {
    enum Localization {
        static let accessibilityLabel = NSLocalizedString(
            "waves.progressView.accessibilityLabel",
            value: "In progress",
            comment: "Default accessibility label for a custom indeterminate progress view.")
    }
}

private struct ArcShape: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                    radius: rect.width / 2,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false)
        return path
    }
}

#Preview {
    ProgressView()
        .progressViewStyle(WaveProgressViewStyle())
}
