import SwiftUI

struct POSBookingDateBarView: View {
    @ScaledMetric private var chevronSize: CGFloat = Constants.chevronSize
    @Environment(\.colorScheme) private var colorScheme

    private var tintColor: Color {
        colorScheme == .dark ? .posSecondary : .posPrimaryContainer
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("dMMMEEE")
        return formatter.string(from: Date())
    }

    var body: some View {
        HStack {
            Button {
                // TODO: Date selector tapped — to be implemented in a future task
            } label: {
                HStack(spacing: POSSpacing.small) {
                    Text(formattedDate)
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(tintColor)

                    Image(systemName: "chevron.down")
                        .font(.system(size: chevronSize, weight: .medium))
                        .foregroundStyle(tintColor)
                }
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, POSPadding.large)
        .padding(.bottom, POSPadding.large)
    }
}

private enum Constants {
    static let chevronSize: CGFloat = 12
}
