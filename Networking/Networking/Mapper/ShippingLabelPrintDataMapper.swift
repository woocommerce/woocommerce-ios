struct ShippingLabelPrintDataMapper: Mapper {
    /// (Attempts) to convert a dictionary into ShippingLabelPrintData.
    ///
    func map(response: Data) throws -> ShippingLabelPrintData {
        try extract(from: response)
    }
}
