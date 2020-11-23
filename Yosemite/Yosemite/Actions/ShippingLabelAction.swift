import Networking

public enum ShippingLabelAction: Action {
    /// Syncs shipping labels for a given order.
    ///
    case synchronizeShippingLabels(siteID: Int64, orderID: Int64, completion: (Result<Void, Error>) -> Void)

    /// Generates a shipping label document for printing.
    ///
    case printShippingLabel(siteID: Int64,
                            shippingLabelID: Int64,
                            paperSize: ShippingLabelPaperSize,
                            completion: (Result<ShippingLabelPrintData, Error>) -> Void)
}
