import SwiftUI
import WooFoundation
import struct Yosemite.POSCustomAmount

struct AddCustomAmountView: View {
    @Environment(\.posMetrics) private var metrics
    @Bindable var viewModel: AddCustomAmountFormViewModel
    let requiresSubmitGuard: Bool
    let onBack: () -> Void
    let onEditAmount: () -> Void
    let onEditName: () -> Void
    let onSubmit: (POSCustomAmount) -> Void

    @State private var hasFinishedSubmitGuard = false
    @State private var hasSubmitted = false

    private var isReadyToSubmit: Bool {
        !requiresSubmitGuard || hasFinishedSubmitGuard
    }

    var body: some View {
        VStack(spacing: 0) {
            POSPageHeaderView(title: Localization.title,
                              backButtonConfiguration: .init(state: .enabled, action: onBack))

            ScrollView {
                VStack(spacing: metrics.spacing.medium) {
                    detailCard(label: Localization.amountLabel,
                               value: viewModel.formattedAmount,
                               isPlaceholder: false,
                               accessibilityLabel: Localization.editAmount,
                               identifier: "pos-custom-amount-amount-card",
                               action: onEditAmount)
                    detailCard(label: Localization.nameLabel,
                               value: viewModel.resolvedName,
                               isPlaceholder: viewModel.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                               accessibilityLabel: Localization.editName,
                               identifier: "pos-custom-amount-name-card",
                               action: onEditName)
                    Toggle(isOn: $viewModel.isTaxable) {
                        Text(Localization.chargeTaxes)
                            .font(.posBodyLargeRegular())
                            .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    }
                    .tint(.posPrimary)
                    .accessibilityIdentifier("pos-custom-amount-tax-toggle")
                    .padding(metrics.padding.xLarge)
                    .background(Color.posSurfaceContainerLowest)
                    .posItemCardBorderStyles()
                }
                .padding(.horizontal, metrics.padding.medium)
                .padding(.bottom, metrics.padding.small)
            }

            Button(action: submit) {
                Text(viewModel.isEditing ? Localization.updateButton : Localization.addButton)
            }
            .buttonStyle(POSFilledButtonStyle(size: .normal))
            .frame(maxWidth: .infinity)
            .disabled(!viewModel.isAddEnabled || hasSubmitted)
            .allowsHitTesting(isReadyToSubmit)
            .accessibilityIdentifier("pos-add-custom-amount-submit-button")
            .padding(metrics.padding.medium)
        }
        .background(Color.posSurfaceBright.ignoresSafeArea())
        .posIgnoresHiddenKeyboardSafeArea()
        .posEdgeSwipeBackAction(onBack: onBack)
        .task {
            guard requiresSubmitGuard else { return }
            // A second tap on Continue or Save must not submit Details in the same button position.
            do {
                try await Task.sleep(for: .milliseconds(300))
            } catch {
                // Leaving Details cancels the delay.
                return
            }
            hasFinishedSubmitGuard = true
        }
    }

    private func detailCard(label: String, value: String, isPlaceholder: Bool,
                            accessibilityLabel: String, identifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: metrics.spacing.medium) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: metrics.spacing.medium) {
                        cardLabel(label)
                        Spacer()
                        cardValue(value, isPlaceholder: isPlaceholder)
                    }
                    VStack(alignment: .leading, spacing: metrics.spacing.small) {
                        cardLabel(label)
                        cardValue(value, isPlaceholder: isPlaceholder)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                Image(systemName: "square.and.pencil")
                    .font(.posBodyLargeRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    .accessibilityHidden(true)
            }
            .padding(metrics.padding.xLarge)
            .background(Color.posSurfaceContainerLowest)
            .posItemCardBorderStyles()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(value)
        .accessibilityIdentifier(identifier)
    }

    private func cardLabel(_ label: String) -> some View {
        Text(label)
            .font(.posBodyLargeRegular())
            .foregroundStyle(Color.posOnSurfaceVariantHighest)
    }

    private func cardValue(_ value: String, isPlaceholder: Bool) -> some View {
        Text(value)
            .font(isPlaceholder ? .posBodyLargeRegular() : .posBodyLargeBold)
            .foregroundStyle(isPlaceholder ? Color.posOnSurfaceVariantLowest : Color.posOnSurface)
    }

    private func submit() {
        guard isReadyToSubmit, !hasSubmitted, let customAmount = viewModel.resolvedCustomAmount() else { return }
        hasSubmitted = true
        onSubmit(customAmount)
    }
}

extension AddCustomAmountView {
    enum Localization {
        static let editAmount = NSLocalizedString(
            "pos.customAmount.details.editAmount", value: "Edit amount",
            comment: "Title of the POS custom amount editor and accessibility label for the Amount card that opens it.")
        static let editName = NSLocalizedString(
            "pos.customAmount.details.editName", value: "Edit name",
            comment: "Accessibility label for the name card in POS custom amount details.")
        static let title = NSLocalizedString(
            "pos.customAmount.details.title",
            value: "Custom amount details",
            comment: "Title of the full-screen Point of Sale form for adding a custom amount to the order.")
        static let amountLabel = NSLocalizedString(
            "pos.addCustomAmount.amountLabel",
            value: "Amount",
            comment: "Label above the amount field in the Point of Sale add custom amount form.")
        static let chargeTaxes = NSLocalizedString(
            "pos.addCustomAmount.chargeTaxes",
            value: "Charge taxes",
            comment: "Title of the taxable toggle in the Point of Sale add custom amount form.")
        static let nameLabel = NSLocalizedString(
            "pos.customAmount.details.nameLabel",
            value: "Name (optional)",
            comment: "Label above the name field in the Point of Sale add custom amount form.")
        static let namePlaceholder = NSLocalizedString(
            "pos.addCustomAmount.namePlaceholder",
            value: "Custom amount",
            comment: "Placeholder for the name field in the Point of Sale add custom amount form.")
        static let addButton = NSLocalizedString(
            "pos.addCustomAmount.addButton",
            value: "Add custom amount",
            comment: "Primary button in the Point of Sale add custom amount form that adds the amount to the order.")
        static let updateButton = NSLocalizedString(
            "pos.addCustomAmount.updateButton",
            value: "Update custom amount",
            comment: "Primary button in the Point of Sale custom amount form when editing, that saves the changes to the order.")
    }
}

#if DEBUG
#Preview {
    AddCustomAmountView(viewModel: AddCustomAmountFormViewModel(currencySettings: CurrencySettings()),
                        requiresSubmitGuard: false,
                        onBack: {}, onEditAmount: {}, onEditName: {}, onSubmit: { _ in })
}
#endif
