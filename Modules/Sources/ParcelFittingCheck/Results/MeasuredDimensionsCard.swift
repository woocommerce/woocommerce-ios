import SwiftUI

struct MeasuredDimensionsCard: View {
    let dimensions: ParcelDimensions
    let unit: UnitLength

    var body: some View {
        Text(dimensions.formatted(unit: unit))
            .font(.title2.bold().monospacedDigit())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Constants.cornerRadius))
    }
}

private extension MeasuredDimensionsCard {
    enum Constants {
        static let cornerRadius: CGFloat = 12
    }
}
