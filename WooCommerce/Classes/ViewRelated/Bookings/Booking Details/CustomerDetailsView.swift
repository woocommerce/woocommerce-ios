import Combine
import SwiftUI

extension BookingDetailsView {
    struct CustomerDetailsView: View {
        @ObservedObject var content: BookingDetailsViewModel.CustomerContent
        let showNotice: (Notice) -> Void
        @State private var showingPhoneOptions = false
        @State private var selectedPhoneNumber: String?

        private enum Row: Hashable {
            case name(String)
            case email(String)
            case phone(String)
            case billingAddress(String)
            case note(String)
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
            if let note = content.noteText, !note.isEmpty {
                result.append(.note(note))
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
            case .note(let noteText):
                noteView(with: noteText)
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
                emailText.sendToPasteboard(includeTrailingNewline: false)
                showNotice(
                    Notice(
                        title: Localization.emailCopiedMessage,
                        feedbackType: .success
                    )
                )
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
                selectedPhoneNumber = phoneText
                showingPhoneOptions = true
            }
            .confirmationDialog(
                selectedPhoneNumber ?? "",
                isPresented: $showingPhoneOptions,
                titleVisibility: .visible
            ) {
                Button(Localization.callActionTitle) {
                    guard let phoneNumber = selectedPhoneNumber else { return }
                    if PhoneHelper.callPhoneNumber(phone: phoneNumber) == false {
                        showNotice(Notice(title: Localization.phoneNumberErrorNotice, feedbackType: .error))
                    }
                }
                Button(Localization.copyActionTitle) {
                    guard let phoneNumber = selectedPhoneNumber else { return }
                    phoneNumber.sendToPasteboard(includeTrailingNewline: false)
                    showNotice(Notice(title: Localization.phoneNumberCopied, feedbackType: .success))
                }
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

        private func noteView(with noteText: String) -> some View {
            HStack {
                VStack(alignment: .leading) {
                    Text(Localization.noteRowTitle)
                        .rowTextStyle()
                    Text(noteText)
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

private extension BookingDetailsView.CustomerDetailsView {
    enum Localization {
        static let emailCopiedMessage = NSLocalizedString(
            "BookingDetailsView.customer.emailCopied.toastMessage",
            value: "Email address copied",
            comment: "Toast message shown when the user copies the customer's email address."
        )

        static let callActionTitle = NSLocalizedString(
            "BookingDetailsView.phoneNumberOptions.call",
            value: "Call",
            comment: "Action to call the phone number."
        )

        static let copyActionTitle = NSLocalizedString(
            "BookingDetailsView.phoneNumberOptions.copy",
            value: "Copy",
            comment: "Action to copy the phone number."
        )

        static let phoneNumberCopied = NSLocalizedString(
            "BookingDetailsView.phoneNumberOptions.copied",
            value: "Phone number copied",
            comment: "Notice message shown when the phone number is copied."
        )

        static let phoneNumberErrorNotice = NSLocalizedString(
            "BookingDetailsView.phoneNumberOptions.error",
            value: "Could not place a call to this number.",
            comment: "Notice message shown when a phone call cannot be initiated."
        )

        /// Customer section
        static let billingAddressRowTitle = NSLocalizedString(
            "BookingDetailsView.customer.billingAddress.title",
            value: "Billing address",
            comment: "Billing address row title in customer section in booking details view."
        )

        static let noteRowTitle = NSLocalizedString(
            "BookingDetailsView.customer.note.title",
            value: "Note",
            comment: "Customer note row title in customer section in booking details view."
        )
    }
}
