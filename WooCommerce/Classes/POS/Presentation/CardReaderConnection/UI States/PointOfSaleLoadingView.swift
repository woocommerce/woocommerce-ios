import SwiftUI

struct PointOfSaleLoadingView: View {
    @State private var waitingTimeTracker: WaitingTimeTracker?

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            VStack(alignment: .center) {
                Spacer()
                ProgressView()
                    .progressViewStyle(POSProgressViewStyle())
                Spacer()
            }
            .multilineTextAlignment(.center)
            Spacer()
        }
        .onAppear {
            trackTimeOnAppear()
        }
        .onDisappear {
            trackElapsedTimeOnDisappear()
        }
    }
}

private extension PointOfSaleLoadingView {
    func trackTimeOnAppear() {
        waitingTimeTracker = WaitingTimeTracker(trackScenario: .pointOfSaleLoaded, analyticsService: ServiceLocator.analytics)
    }

    func trackElapsedTimeOnDisappear() {
        if let waitingTimeTracker = waitingTimeTracker {
            waitingTimeTracker.end()
        }
    }
}

private extension PointOfSaleLoadingView {
    enum Layout {
        static let textSpacing: CGFloat = 16
        static let progressViewSpacing: CGFloat = 72
    }
    enum Constants {
        static let toMilliseconds: Double = 1000.0
    }
}

#Preview {
    PointOfSaleLoadingView()
}
