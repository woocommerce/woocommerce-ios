struct CouponReportListMapper: Mapper {

    /// (Attempts) to convert a dictionary into `[CouponReport]`.
    ///
    func map(response: Data) throws -> [CouponReport] {
        try extract(from: response, using: JSONDecoder())
    }
}
