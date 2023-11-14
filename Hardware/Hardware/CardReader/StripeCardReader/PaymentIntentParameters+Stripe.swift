#if !targetEnvironment(macCatalyst)
import StripeTerminal

extension Hardware.PaymentIntentParameters {
    /// Initializes a StripeTerminal.PaymentIntentParameters from a
    /// Hardware.PaymentIntentParameters
    func toStripe(with cardReaderMetadata: CardReaderMetadata? = nil) -> StripeTerminal.PaymentIntentParameters? {
        // Shortcircuit if we do not have a valid currency code
        guard !currency.isEmpty else {
            return nil
        }

        // Shortcircuit if we do not have a valid payment method
        guard !paymentMethodTypes.isEmpty else {
            return nil
        }

        let amountForStripe = prepareAmountForStripe(amount)

        let paymentIntentParamBuilder: PaymentIntentParametersBuilder = StripeTerminal.PaymentIntentParametersBuilder(amount: amountForStripe,
                                                                                                                      currency: currency)

        do {
            paymentIntentParamBuilder.setPaymentMethodTypes(paymentMethodTypes)
            paymentIntentParamBuilder.setStripeDescription(receiptDescription)

            /// Stripe allows the credit card statement descriptor to be nil, but not an empty string
            /// https://stripe.dev/stripe-terminal-ios/docs/Classes/SCPPaymentIntentParameters.html#/c:objc(cs)SCPPaymentIntentParameters(py)statementDescriptor
            paymentIntentParamBuilder.setStatementDescriptor(nil)

            let descriptor = statementDescription ?? ""
            if !descriptor.isEmpty {
                paymentIntentParamBuilder.setStatementDescriptor(descriptor)
            }

            if let applicationFee = applicationFee {
                /// Stripe requires that "The amount must be provided as a boxed UInt in the currency's smallest unit."
                /// Smallest-unit and UInt conversion is done in the same way as for the total amount, but that does not need to be boxed.
                let applicationFeeForStripe = NSNumber(value: prepareAmountForStripe(applicationFee))
                paymentIntentParamBuilder.setApplicationFeeAmount(applicationFeeForStripe)
            }

            paymentIntentParamBuilder.setReceiptEmail(receiptEmail)

            let updatedMetadata = prepareMetadataForStripe(with: cardReaderMetadata)
            paymentIntentParamBuilder.setMetadata(updatedMetadata)

            // Return payment intent built config:
            return try paymentIntentParamBuilder.build()
        } catch {
            // TODO: Better error handling
            return nil
        }
    }
}

private extension Hardware.PaymentIntentParameters {
    func prepareAmountForStripe(_ amount: Decimal) -> UInt {
        let amountInSmallestUnit = amount * stripeSmallestCurrencyUnitMultiplier
        return NSDecimalNumber(decimal: amountInSmallestUnit).uintValue
    }

    func prepareMetadataForStripe(with meta: CardReaderMetadata? = nil) -> [String: String]? {
        let cardReaderMetadata: [String: String]? = [
            "reader_ID": "\(meta?.readerIDMetadataKey ?? "")",
            "reader_model": "\(meta?.readerModelMetadataKey ?? "")",
            "platform": "\(meta?.platformMetadataKey ?? "")"
        ]

        // Updates the existing PaymentIntentParameters metadata with our cardReaderMetaData when there's a key collision in the dictionary
        let updatedMetadata = (metadata ?? [:]).merging(cardReaderMetadata ?? [:]) { (_, new) in new }

        return updatedMetadata
    }
}
#endif
