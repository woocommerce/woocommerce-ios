import SwiftUI

struct ARDimensionTile: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: Constants.innerSpacing) {
            Text(label)
                .font(.caption2.bold())
                .tracking(Constants.labelTracking)
                .foregroundStyle(.white.opacity(Constants.secondaryOpacity))

            Text(value)
                .font(.title2.monospacedDigit().weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(Constants.minimumScaleFactor)

            Text(unit)
                .font(.caption2)
                .foregroundStyle(.white)
        }
        .padding(.vertical, Constants.verticalPadding)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(Constants.backgroundOpacity), in: RoundedRectangle(cornerRadius: Constants.cornerRadius))
    }
}

private extension ARDimensionTile {
    enum Constants {
        static let innerSpacing: CGFloat = 2
        static let verticalPadding: CGFloat = 8
        static let cornerRadius: CGFloat = 10
        static let labelTracking: CGFloat = 1
        static let backgroundOpacity: Double = 0.08
        static let secondaryOpacity: Double = 0.55
        static let minimumScaleFactor: CGFloat = 0.7
    }
}
