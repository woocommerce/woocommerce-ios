import Foundation
import class WooFoundation.CurrencyFormatter

final class CollectCashViewHelper {
    private let currencyFormatter: CurrencyFormatter = WooFoundation.CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)

    func updatechangeDueMessage(orderTotal: String,
                                textFieldAmountInput: String) -> String? {
        guard let orderDecimal = parseCurrency(orderTotal),
              let inputDecimal = parseCurrency(textFieldAmountInput) else {
            return nil
        }
        if inputDecimal.compare(orderDecimal) == .orderedDescending {
            let changeDue = inputDecimal.subtracting(orderDecimal)
            return  String.localizedStringWithFormat(Localization.changeDueMessage, formatAsCurrency(changeDue))
        } else {
            return nil
        }
    }

    func validateAmountOnSubmit(orderTotal: String,
                                textFieldAmountInput: String,
                                onError: (String) -> Void) -> Bool {
        guard let orderDecimal = parseCurrency(orderTotal),
              let inputDecimal = parseCurrency(textFieldAmountInput) else {
            onError(Localization.failedToCollectCashPayment)
            return false
        }

        if inputDecimal.compare(orderDecimal) == .orderedAscending {
            onError(Localization.cashPaymentAmountNotEnough)
            return false
        }
        return true
    }

    func parseCurrency(_ amountString: String) -> NSDecimalNumber? {
        currencyFormatter.convertToDecimal(amountString, locale: .current)
    }

    func formatAsCurrency(_ amount: NSDecimalNumber) -> String {
        currencyFormatter.formatAmount(amount) ?? "$0.00"
    }
}

private extension CollectCashViewHelper {
    enum Localization {
        static let changeDueMessage = NSLocalizedString(
            "collectcashviewhelper.changedue",
            value: "Change due: %1$@",
            comment: "Change due when the cash amount entered exceeds the order total." +
            "Reads as 'Change due: $1.23'"
        )
        static let failedToCollectCashPayment = NSLocalizedString(
            "collectcashviewhelper.failedtocollectcashpayment.errormessage",
            value: "Error trying to process payment. Try again.",
            comment: "Error message when the system fails to collect a cash payment."
        )
        static let cashPaymentAmountNotEnough = NSLocalizedString(
            "collectcashviewhelper.cashpaymentamountnotenough.errormessage",
            value: "Amount must be more or equal to total.",
            comment: "Error message when the cash amount entered is less than the order total."
        )
    }
}
