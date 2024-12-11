import Foundation
import SwiftUI

struct CardPresentPaymentsLocationPreAlertView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ScrollableVStack(padding: 0, spacing: 20) {
                    Image("card-reader-location-permission")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 104, maxHeight: 104, alignment: .center)
                    Spacer().frame(maxHeight: 40)
                    Text(Localization.title)
                        .font(.title.weight(.bold))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(Localization.subtitle)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .scrollIndicators(.hidden)

                Button(Localization.continueButton, action: {

                })
                .buttonStyle(PrimaryButtonStyle())

                HStack {
                    Image(systemName: "info.circle")
                    Text(Localization.settings)
                        .font(.caption)
                    Spacer()
                }
            }
            .padding()
        }
        .interactiveDismissDisabled()
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "cardPresentPayment.locationPreAlert.title",
        value: "Enable location services on the next screen to allow payments.",
        comment: "A title explaining why location services are needed to make a payment"
    )

    static let subtitle = NSLocalizedString(
        "cardPresentPayment.locationPreAlert.subtitle",
        value: "Location services permission is required to reduce fraud, prevent disputes, and ensure secure payments.",
        comment: "A subtitle explaining why location services are needed to make a payment"
    )

    static let settings = NSLocalizedString(
        "cardPresentPayment.locationPreAlert.settingsNotice",
        value: "You can change this option later in the Settings app.",
        comment: "A notice at the bottom explaining that location services can be changes in the Settings app later"
    )

    static let continueButton = NSLocalizedString(
        "cardPresentPayment.locationPreAlert.continueButton",
        value: "Continue",
        comment: "A title for CTA to present native location permission alert"
    )
}

#Preview {
    CardPresentPaymentsLocationPreAlertView()
}
