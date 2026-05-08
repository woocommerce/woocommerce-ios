import SwiftUI

struct NoCarrierMatchView: View {
    var body: some View {
        HStack(spacing: Constants.spacing) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
            Text(Localization.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Constants.cornerRadius))
    }
}

private extension NoCarrierMatchView {
    enum Constants {
        static let spacing: CGFloat = 12
        static let cornerRadius: CGFloat = 12
    }

    enum Localization {
        static let message = NSLocalizedString(
            "parcelFitting.results.noCarrierMatch.message",
            value: "We couldn't find a carrier package that fits your item. Use your exact size below to get rate quotes.",
            comment: "Message shown when no carrier packages fit the measured dimensions on the AR results screen")
    }
}
