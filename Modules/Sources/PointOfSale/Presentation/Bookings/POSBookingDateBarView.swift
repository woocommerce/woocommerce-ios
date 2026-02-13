import SwiftUI

struct POSBookingDateBarView: View {
    let currentSortOption: POSBookingSortOption
    let onSortOptionSelected: (POSBookingSortOption) -> Void

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

            Menu {
                ForEach(POSBookingSortOption.allCases, id: \.self) { option in
                    Button {
                        onSortOptionSelected(option)
                    } label: {
                        if option == currentSortOption {
                            Label(option.title, systemImage: "checkmark")
                        } else {
                            Text(option.title)
                        }
                    }
                }
            } label: {
                Text(Localization.sortBy)
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(tintColor)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Localization.sortButtonAccessibilityLabel)
        }
        .padding(.horizontal, POSPadding.large)
        .padding(.bottom, POSPadding.large)
    }
}

private enum Constants {
    static let chevronSize: CGFloat = 12
}

private enum Localization {
    static let sortBy = NSLocalizedString(
        "pos.bookingDateBar.sortBy",
        value: "Sort by",
        comment: "Label for the sort menu button in the bookings date bar"
    )
    static let sortButtonAccessibilityLabel = NSLocalizedString(
        "pos.bookingDateBar.sortButton.accessibilityLabel",
        value: "Sort bookings",
        comment: "Accessibility label for the sort button in the bookings date bar"
    )
}
