// POSBookingCashPaymentView.swift
import SwiftUI

struct POSBookingCashPaymentView: View {
    let booking: POSBooking
    let onPaymentComplete: () -> Void
    let onDismiss: () -> Void
    let onEmailReceipt: () -> Void

    @Environment(\.posAnalytics) private var analytics
    @State private var tenderedAmount: String = ""
    @State private var showSuccess: Bool = false
    @State private var isProcessing: Bool = false

    private var bookingAmount: Decimal {
        // Parse amount from formatted string (e.g., "$50.00" -> 50.00)
        let cleanedAmount = booking.amount.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
        return Decimal(string: cleanedAmount) ?? 0
    }

    private var tenderedDecimal: Decimal {
        Decimal(string: tenderedAmount) ?? 0
    }

    private var changeDue: Decimal {
        max(tenderedDecimal - bookingAmount, 0)
    }

    private var canComplete: Bool {
        tenderedDecimal >= bookingAmount
    }

    var body: some View {
        VStack(spacing: POSSpacing.xxLarge) {
            Spacer()

            if showSuccess {
                successContent
            } else {
                cashEntryContent
            }

            Spacer()

            actionButtons
        }
        .padding(POSSpacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.posSurface)
    }

    @ViewBuilder
    private var cashEntryContent: some View {
        VStack(spacing: POSSpacing.large) {
            Text(Localization.totalDue)
                .font(.posBodyLargeRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)

            Text(booking.amount)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(Color.posOnSurface)

            VStack(spacing: POSSpacing.small) {
                Text(Localization.amountTendered)
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)

                TextField("0.00", text: $tenderedAmount)
                    .font(.system(size: 32, weight: .bold))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.posOnSurface)
            }

            if tenderedDecimal > 0 && canComplete {
                VStack(spacing: POSSpacing.xSmall) {
                    Text(Localization.changeDue)
                        .font(.posBodyMediumRegular())
                        .foregroundStyle(Color.posOnSurfaceVariantHighest)

                    Text(formatCurrency(changeDue))
                        .font(.posBodyXLargeBold)
                        .foregroundStyle(Color.posSuccess)
                }
            }
        }
    }

    @ViewBuilder
    private var successContent: some View {
        VStack(spacing: POSSpacing.large) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.posSuccess)

            Text(Localization.paymentSuccessful)
                .font(.posBodyXLargeBold)
                .foregroundStyle(Color.posOnSurface)

            Text(booking.amount)
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(Color.posOnSurface)
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        if showSuccess {
            VStack(spacing: POSSpacing.medium) {
                Button(Localization.emailReceipt) {
                    onEmailReceipt()
                }
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))

                Button(Localization.done) {
                    onPaymentComplete()
                }
                .buttonStyle(POSFilledButtonStyle(size: .normal))
            }
        } else {
            VStack(spacing: POSSpacing.medium) {
                Button(Localization.markAsPaid) {
                    completePayment()
                }
                .buttonStyle(POSFilledButtonStyle(size: .normal, state: isProcessing ? .loading : .idle))
                .disabled(!canComplete || isProcessing)

                Button(Localization.cancel) {
                    onDismiss()
                }
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                .disabled(isProcessing)
            }
        }
    }

    private func completePayment() {
        isProcessing = true

        // In the real implementation, this would call the booking service
        // to mark the booking as paid. For now, we just show success.
        Task { @MainActor in
            // Simulate network call
            try? await Task.sleep(nanoseconds: 500_000_000)
            showSuccess = true
            isProcessing = false
        }
    }

    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: amount as NSNumber) ?? "\(amount)"
    }

    private enum Localization {
        static let totalDue = NSLocalizedString("posBookingCash.totalDue", value: "Total Due", comment: "Label for total amount")
        static let amountTendered = NSLocalizedString("posBookingCash.amountTendered", value: "Amount Tendered", comment: "Label for cash amount")
        static let changeDue = NSLocalizedString("posBookingCash.changeDue", value: "Change Due", comment: "Label for change amount")
        static let markAsPaid = NSLocalizedString("posBookingCash.markAsPaid", value: "Mark as Paid", comment: "Button to complete cash payment")
        static let cancel = NSLocalizedString("posBookingCash.cancel", value: "Cancel", comment: "Cancel button")
        static let paymentSuccessful = NSLocalizedString("posBookingCash.success", value: "Payment Successful", comment: "Success message")
        static let done = NSLocalizedString("posBookingCash.done", value: "Done", comment: "Done button")
        static let emailReceipt = NSLocalizedString("posBookingCash.emailReceipt", value: "Email Receipt", comment: "Email receipt button")
    }
}
