import Combine
import SwiftUI

extension BookingDetailsView {
    struct CustomerDetailsView: View {
        @ObservedObject var content: BookingDetailsViewModel.CustomerContent

        var body: some View {
            VStack(spacing: 0) {
                /// Name
                if let nameText = content.nameText, !nameText.isEmpty {
                    HStack {
                        Text(nameText)
                            .rowTextStyle()
                        Spacer()
                    }
                    .padding(.vertical, Layout.rowTextVerticalPadding)

                    Divider()
                        .padding(.trailing, -Layout.contentSidePadding)
                }

                /// Email
                if let emailText = content.emailText, !emailText.isEmpty {
                    HStack {
                        Text(emailText)
                            .rowTextStyle()
                        Spacer()
                        Image(systemName: "doc.on.doc")
                            .font(TextFont.bodyMedium)
                            .foregroundStyle(Color.accentColor)
                    }
                    .padding(.vertical, Layout.rowTextVerticalPadding)
                    .tappable {
                        print("On email copy")
                    }

                    Divider()
                        .padding(.trailing, -Layout.contentSidePadding)
                }

                /// Phone
                if let phoneText = content.phoneText, !phoneText.isEmpty {
                    HStack {
                        Text(phoneText)
                            .rowTextStyle()
                        Spacer()
                        Image(systemName: "ellipsis")
                            .font(TextFont.bodyMedium)
                            .foregroundStyle(Color.accentColor)
                    }
                    .padding(.vertical, Layout.rowTextVerticalPadding)
                    .tappable {
                        print("On phone ellipsis")
                    }

                    Divider()
                        .padding(.trailing, -Layout.contentSidePadding)
                }


                /// Billing address
                if let billingAddressText = content.billingAddressText, !billingAddressText.isEmpty {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(Localization.billingAddressRowTitle)
                                .rowTextStyle()
                            Text(billingAddressText)
                                .font(TextFont.bodyMedium)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                    }
                    .padding(.vertical, Layout.rowTextVerticalPadding)
                }
            }
        }
    }
}
