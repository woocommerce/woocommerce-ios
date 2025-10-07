import Combine
import SwiftUI

extension BookingDetailsView {
    struct CustomerDetailsView: View {
        @ObservedObject var content: BookingDetailsViewModel.CustomerContent

        private enum Row: Hashable {
            case name(String)
            case email(String)
            case phone(String)
            case billingAddress(String)
        }

        private var rows: [Row] {
            var result = [Row]()
            if let name = content.nameText, !name.isEmpty {
                result.append(.name(name))
            }
            if let email = content.emailText, !email.isEmpty {
                result.append(.email(email))
            }
            if let phone = content.phoneText, !phone.isEmpty {
                result.append(.phone(phone))
            }
            if let address = content.billingAddressText, !address.isEmpty {
                result.append(.billingAddress(address))
            }
            return result
        }

        var body: some View {
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element) { index, row in
                    view(for: row)

                    if index < rows.count - 1 {
                        Divider()
                            .padding(.trailing, -Layout.contentSidePadding)
                    }
                }
            }
        }

        @ViewBuilder
        private func view(for row: Row) -> some View {
            switch row {
            case .name(let nameText):
                nameView(with: nameText)
            case .email(let emailText):
                emailView(with: emailText)
            case .phone(let phoneText):
                phoneView(with: phoneText)
            case .billingAddress(let billingAddressText):
                billingAddressView(with: billingAddressText)
            }
        }

        private func nameView(with nameText: String) -> some View {
            HStack {
                Text(nameText)
                    .rowTextStyle()
                Spacer()
            }
            .padding(.vertical, Layout.rowTextVerticalPadding)
        }

        private func emailView(with emailText: String) -> some View {
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
        }

        private func phoneView(with phoneText: String) -> some View {
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
        }

        private func billingAddressView(with billingAddressText: String) -> some View {
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
