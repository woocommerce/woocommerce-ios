import SwiftUI

struct POSBookingDateBarView: View {
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("dMMMEEE")
        return formatter.string(from: Date())
    }

    var body: some View {
        HStack {
            Button(action: {}) {
                HStack(spacing: POSSpacing.small) {
                    Text(formattedDate)
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(Color.posPrimaryContainer)

                    Image(systemName: "chevron.down")
                        .font(.system(size: Constants.chevronSize, weight: .medium))
                        .foregroundStyle(Color.posPrimaryContainer)
                }
            }
            .disabled(true)

            Spacer()
        }
        .padding(.horizontal, POSPadding.large)
        .padding(.bottom, POSPadding.large)
    }
}

private enum Constants {
    static let chevronSize: CGFloat = 12
}
