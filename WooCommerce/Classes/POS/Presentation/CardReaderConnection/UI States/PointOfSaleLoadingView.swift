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
        .background(Color.posSurface)
    }
}

private extension PointOfSaleLoadingView {
    func trackTimeOnAppear() {
        waitingTimeTracker = WaitingTimeTracker(trackScenario: .pointOfSaleLoaded)
    }

    func trackElapsedTimeOnDisappear() {
        if let waitingTimeTracker = waitingTimeTracker {
            waitingTimeTracker.end(using: .milliseconds)
        }
    }
}

#Preview {
    PointOfSaleLoadingView()
}
