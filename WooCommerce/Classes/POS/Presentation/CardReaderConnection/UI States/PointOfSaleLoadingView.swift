import SwiftUI

struct PointOfSaleLoadingView: View {
    @State private var appearTimeInMilliseconds: TimeInterval?

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
        appearTimeInMilliseconds = Date().timeIntervalSince1970 * Constants.toMilliseconds
    }

    func trackElapsedTimeOnDisappear() {
        if let appearTimeInMilliseconds = appearTimeInMilliseconds {
            let elapsedTimeInMilliseconds = (Date().timeIntervalSince1970 * Constants.toMilliseconds) - appearTimeInMilliseconds
            ServiceLocator.analytics.track(event: .PointOfSale.pointOfSaleInitialLoadingTime(elapsedTimeInMilliseconds))
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
