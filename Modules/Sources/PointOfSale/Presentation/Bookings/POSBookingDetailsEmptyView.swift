// POSBookingDetailsEmptyView.swift
import SwiftUI

/// Empty state view shown when no booking is selected in the detail pane
struct POSBookingDetailsEmptyView: View {
    var body: some View {
        VStack(spacing: POSSpacing.medium) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundStyle(Color.posOnSurfaceVariantHighest)

            Text(Localization.selectBooking)
                .font(.posBodyLargeRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.posSurface)
    }

    private enum Localization {
        static let selectBooking = NSLocalizedString(
            "posBookingDetailsEmpty.selectBooking",
            value: "Select a booking to view details",
            comment: "Placeholder when no booking is selected"
        )
    }
}
