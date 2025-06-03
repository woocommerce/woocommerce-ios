import SwiftUI
import struct Yosemite.ShippingLabelPaymentMethod
import struct Yosemite.ShippingLabelAccountSettings

struct WooShippingPaymentMethodsView: View {

    @ObservedObject var viewModel: ShippingLabelPaymentMethodsViewModel

    let onAccountSettingsUpdate: (ShippingLabelAccountSettings) -> Void

    @State private var failedToUpdateSettings = false

    var body: some View {
        ScrollableVStack(alignment: .leading, padding: Layout.contentPadding, spacing: Layout.contentSpacing) {
            Text(Localization.title)
                .font(.title3)
                .bold()

            Text(Localization.subtitle)
                .padding(.bottom, Layout.contentPadding)

            if viewModel.canEditPaymentMethod == false {
                paymentMethodsNotEditableView
            }

            if viewModel.paymentMethods.isEmpty {
                emptyView
                    .disabled(viewModel.canEditPaymentMethod == false)
            } else {
                paymentMethodList
                    .disabled(viewModel.canEditPaymentMethod == false)
            }

            HStack(alignment: .top) {
                Image(systemName: "info.circle")
                Text(String.localizedStringWithFormat(Localization.note,
                                                      viewModel.storeOwnerDisplayName,
                                                      viewModel.storeOwnerUsername))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.footnote)
            .foregroundStyle(Color.primary)
            .accessibilityElement(children: .combine)
            .padding(.top, Layout.contentSpacing)

            Spacer()

            if viewModel.paymentMethods.isNotEmpty {
                VStack(spacing: Layout.contentPadding) {
                    Divider()
                        .padding(.horizontal, -Layout.contentPadding) // hack to cancel the padding set by parent

                    Toggle(isOn: $viewModel.isEmailReceiptsEnabled) {
                        Text(Localization.emailReceipt)
                    }
                    .toggleStyle(.switch)

                    Button(Localization.confirmButton) {
                        Task {
                            await confirmPaymentMethod()
                        }
                    }
                    .buttonStyle(PrimaryLoadingButtonStyle(isLoading: viewModel.isUpdating))
                    .disabled(viewModel.isDoneButtonEnabled() == false)
                }
            }
        }
        .padding(.top, Layout.contentPadding)
        .onAppear {
            DispatchQueue.main.async {
                /// clears states from last time.
                viewModel.resetViewStates()
            }
        }
        .alert(Localization.ConfirmError.title, isPresented: $failedToUpdateSettings) {
            Button(Localization.ConfirmError.retry) {
                Task {
                    await confirmPaymentMethod()
                }
            }
            Button(Localization.ConfirmError.cancel, role: .cancel) {}
        }
    }
}

private extension WooShippingPaymentMethodsView {
    var paymentMethodsNotEditableView: some View {
        HStack(alignment: .top) {
            Image(systemName: "info.circle")
                .foregroundStyle(Color(uiColor: .warning))
            Text(String.localizedStringWithFormat(Localization.paymentMethodsNotEditableNote,
                                                  viewModel.storeOwnerDisplayName,
                                                  viewModel.storeOwnerUsername))
                .multilineTextAlignment(.leading)
        }
        .font(.subheadline)
        .padding(Layout.contentPadding)
        .background(
            Color(uiColor: .warningBackground)
                .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        )
        .accessibilityElement(children: .combine)
    }

    var emptyView: some View {
        VStack(spacing: Layout.EmptyView.contentSpacing) {
            Image(uiImage: .creditCardIllustration)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Layout.EmptyView.imageSize, height: Layout.EmptyView.imageSize)
                .accessibilityHidden(true)

            VStack(spacing: Layout.EmptyView.textSpacing) {
                Text(Localization.EmptyView.title)
                    .font(.subheadline)
                    .bold()
                Text(Localization.EmptyView.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)

            Button {
                // TODO
            } label: {
                Label {
                    Text(Localization.EmptyView.actionButton)
                } icon: {
                    Image(uiImage: .externalImage)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(Layout.EmptyView.contentInsets)
        .background(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .stroke(Color(.border), style: StrokeStyle(dash: [4, 4]))
        )
        .padding(.vertical, Layout.contentSpacing)
    }

    var paymentMethodList: some View {
        VStack {
            ForEach(viewModel.paymentMethods, id: \.paymentMethodID) { method in
                Button {
                    viewModel.didSelectPaymentMethod(withID: method.paymentMethodID)
                } label: {
                    VStack(alignment: .leading) {
                        Text(method.cardLineTitle)
                            .bold()
                        Text(method.name)
                        Text(method.expiryString)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Layout.contentPadding)
                    .contentShape(Rectangle())
                    .background(
                        RoundedRectangle(cornerRadius: Layout.cornerRadius)
                            .fill(isSelectedMethod(method) ? Layout.selectedBackgroundColor : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                                    .stroke(
                                        isSelectedMethod(method) ? Color.accentColor : Color(.border),
                                        lineWidth: isSelectedMethod(method) ? Layout.selectedBorderWidth : Layout.borderWidth
                                    )
                            )
                    )
                }
            }
            .buttonStyle(.plain)

            Button {
                // TODO
            } label: {
                HStack(spacing: Layout.contentPadding) {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.accentColor)
                    Text(Localization.EmptyView.actionButton)
                }
                .font(.subheadline)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Layout.contentPadding)
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: Layout.cornerRadius)
                        .stroke(Color(.border))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, Layout.contentSpacing)
    }
}

// MARK: - Helpers
private extension WooShippingPaymentMethodsView {
    func isSelectedMethod(_ method: ShippingLabelPaymentMethod) -> Bool {
        method.paymentMethodID == viewModel.selectedPaymentMethodID
    }

    @MainActor
    func confirmPaymentMethod() async {
        do {
            let newSettings = try await viewModel.updateWooShippingAccountSettings()
            onAccountSettingsUpdate(newSettings)
        } catch {
            DDLogError("⛔️ Error saving account settings: \(error)")
            failedToUpdateSettings = true
        }
    }
}

// MARK: - Subtypes
private extension WooShippingPaymentMethodsView {
    enum Layout {
        static let contentPadding: CGFloat = 16
        static let contentSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 8
        static let borderWidth: CGFloat = 0.5
        static let selectedBorderWidth: CGFloat = 2
        enum EmptyView {
            static let contentInsets = EdgeInsets(top: 54, leading: 32, bottom: 54, trailing: 32)
            static let contentSpacing: CGFloat = 16
            static let textSpacing: CGFloat = 8
            static let imageSize: CGFloat = 88
        }
        static let selectedBackgroundColor = Color(
            light: .withColorStudio(name: .wooCommercePurple, shade: .shade0),
            dark: .withColorStudio(name: .wooCommercePurple, shade: .shade80)
        )
    }
}

private extension WooShippingPaymentMethodsView {
    enum Localization {
        static let title = NSLocalizedString(
            "wooShippingPaymentMethodsView.title",
            value: "Payment method",
            comment: "Title of the payment method sheet in the Shipping Label purchase flow"
        )
        static let subtitle = NSLocalizedString(
            "wooShippingPaymentMethodsView.subtitle",
            value: "Choose a payment method.",
            comment: "Subtitle of the payment method sheet in the Shipping Label purchase flow"
        )
        static let paymentMethodsNotEditableNote = NSLocalizedString(
            "wooShippingPaymentMethodsView.paymentMethodsNotEditableNote",
            value: "Only the site owner can manage the shipping label payment methods. " +
            "Please contact store owner %1$@ (%2$@) to manage payment methods",
            comment: "Note for users without permission to manage payment methods for shipping label purchase. " +
            "The placeholders are the store owner name and username respectively."
        )
        enum EmptyView {
            static let title = NSLocalizedString(
                "wooShippingPaymentMethodsView.emptyView.title",
                value: "Add a payment method",
                comment: "Title of the payment method empty sheet in the Shipping Label purchase flow"
            )
            static let subtitle = NSLocalizedString(
                "wooShippingPaymentMethodsView.emptyView.subtitle",
                value: "Add a payment method to purchase a shipping label",
                comment: "Subtitle of the payment method empty sheet in the Shipping Label purchase flow"
            )
            static let actionButton = NSLocalizedString(
                "wooShippingPaymentMethodsView.emptyView.actionButton",
                value: "New credit or debit card",
                comment: "Action button on the payment method empty sheet in the Shipping Label purchase flow"
            )
        }
        static let note = NSLocalizedString(
            "wooShippingPaymentMethodsView.noteWithUsername",
            value: "Credit cards are retrieved from the following WordPress.com account: %1$@ <@%2$@>.",
            comment: "Note of the payment method sheet in the Shipping Label purchase flow. " +
            "Placeholders are the name and username of an associated WordPress account. " +
            "Please keep the `@` in front of the second placeholder."
        )
        static let emailReceipt = NSLocalizedString(
            "wooShippingPaymentMethodsView.emailReceipt",
            value: "Email the receipt",
            comment: "Label of the toggle to enable emailing receipt upon purchasing a shipping label"
        )
        static let confirmButton = NSLocalizedString(
            "wooShippingPaymentMethodsView.confirmButton",
            value: "Use this card",
            comment: "Button to confirm a credit/debit for purchasing a shipping label"
        )

        enum ConfirmError {
            static let title = NSLocalizedString(
                "wooShippingPaymentMethodsView.confirmError.title",
                value: "Unable to confirm the payment method",
                comment: "Title of the error alert when confirming a payment method for purchasing shipping label fails"
            )
            static let retry = NSLocalizedString(
                "wooShippingPaymentMethodsView.confirmError.retry",
                value: "Retry",
                comment: "Button to retry on the error alert when confirming a payment method for purchasing shipping label fails"
            )
            static let cancel = NSLocalizedString(
                "wooShippingPaymentMethodsView.confirmError.cancel",
                value: "Cancel",
                comment: "Button to dismiss the error alert when confirming a payment method for purchasing shipping label fails"
            )
        }
    }
}

#Preview {
    WooShippingPaymentMethodsView(
        viewModel: .init(accountSettings: ShippingLabelPaymentMethodsViewModel.sampleAccountSettings()),
        onAccountSettingsUpdate: { _ in }
    )
}

#Preview {
    WooShippingPaymentMethodsView(
        viewModel: .init(accountSettings: ShippingLabelPaymentMethodsViewModel.sampleAccountSettings(withPermissions: false)),
        onAccountSettingsUpdate: { _ in }
    )
}

#Preview {
    WooShippingPaymentMethodsView(
        viewModel: .init(accountSettings: ShippingLabelPaymentMethodsViewModel.sampleAccountSettings(
            withPermissions: false,
            hasPaymentMethods: false
        )),
        onAccountSettingsUpdate: { _ in }
    )
}

#Preview {
    WooShippingPaymentMethodsView(
        viewModel: .init(accountSettings: ShippingLabelPaymentMethodsViewModel.sampleAccountSettings(
            withPermissions: true,
            hasPaymentMethods: false
        )),
        onAccountSettingsUpdate: { _ in }
    )
}
