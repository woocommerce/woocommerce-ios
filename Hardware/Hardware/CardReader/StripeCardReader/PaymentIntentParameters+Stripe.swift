#if !targetEnvironment(macCatalyst)
import StripeTerminal

extension Hardware.PaymentIntentParameters {
    /// Initializes a StripeTerminal.PaymentIntentParameters from a
    /// Hardware.PaymentIntentParameters
    func toStripe(with cardReaderMetadata: CardReaderMetadata? = nil) -> StripeTerminal.PaymentIntentParameters? {
        // Shortcircuit if we do not have a valid currency code, or a valid payment method
        guard !currency.isEmpty, !paymentMethodTypes.isEmpty else {
            return nil
        }

        let amountForStripe = prepareAmountForStripe(amount)
        let paymentIntentParametersBuilder = createPaymentIntentParametersBuilder(amount: amountForStripe, currency: currency)

        do {
            return try build(paymentIntentParametersBuilder, with: cardReaderMetadata)
        } catch {
            DDLogError("Failed to build PaymentIntentParameters. Error:\(error)")
            return nil
        }
    }
}

private extension Hardware.PaymentIntentParameters {
    func prepareAmountForStripe(_ amount: Decimal) -> UInt {
        let amountInSmallestUnit = amount * stripeSmallestCurrencyUnitMultiplier
        return NSDecimalNumber(decimal: amountInSmallestUnit).uintValue
    }

    func createPaymentIntentParametersBuilder(amount: UInt, currency: String) -> PaymentIntentParametersBuilder {
        StripeTerminal.PaymentIntentParametersBuilder(amount: amount, currency: currency)
    }

    func build(_ builder: PaymentIntentParametersBuilder,
               with cardReaderMetadata: CardReaderMetadata? = nil) throws -> StripeTerminal.PaymentIntentParameters? {
            builder.setPaymentMethodTypes(paymentMethodTypes)
            builder.setStripeDescription(receiptDescription)

            /// Stripe allows the credit card statement descriptor to be nil, but not an empty string
            /// https://stripe.dev/stripe-terminal-ios/docs/Classes/SCPPaymentIntentParameters.html#/c:objc(cs)SCPPaymentIntentParameters(py)statementDescriptor
            builder.setStatementDescriptor(nil)

            let descriptor = statementDescription ?? ""
            if !descriptor.isEmpty {
                builder.setStatementDescriptor(descriptor)
            }

            if let applicationFee = applicationFee {
                /// Stripe requires that "The amount must be provided as a boxed UInt in the currency's smallest unit."
                /// Smallest-unit and UInt conversion is done in the same way as for the total amount, but that does not need to be boxed.
                let applicationFeeForStripe = NSNumber(value: prepareAmountForStripe(applicationFee))
                builder.setApplicationFeeAmount(applicationFeeForStripe)
            }

            builder.setReceiptEmail(receiptEmail)

            let updatedMetadata = prepareMetadataForStripe(with: cardReaderMetadata)
            builder.setMetadata(updatedMetadata)

            // Return payment intent built configuration:
            return try builder.build()
    }

    /// Updates the existing PaymentIntentParameters metadata with our CardReader metadata, if any.
    ///
    func prepareMetadataForStripe(with meta: CardReaderMetadata? = nil) -> [String: String]? {
        guard let meta = meta else {
            return metadata
        }

        let cardReaderMetadata: [String: String] = [
            "reader_ID": "\(meta.readerIDMetadataKey)",
            "reader_model": "\(meta.readerModelMetadataKey)",
            "platform": "\(meta.platformMetadataKey)"
        ]

        let updatedMetadata = metadata?.merging(cardReaderMetadata) { (_, new) in new }

        return updatedMetadata
    }
}
#endif
