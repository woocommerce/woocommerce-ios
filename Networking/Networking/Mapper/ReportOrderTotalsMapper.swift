import Foundation


/// Mapper: Order totals report
///
struct ReportOrderTotalsMapper: Mapper {
    /// (Attempts) to extract order totals report from a given JSON Encoded response.
    ///
    func map(response: Data) throws -> [OrderStatus: Int] {
        let totalsArray = try JSONDecoder().decode(ReportOrderTotalsEnvelope.self, from: response).totals
        var returnDict = [OrderStatus: Int]()
        totalsArray.forEach({ (totalResult) in
            guard let slug = totalResult[Constants.slugKey]?.value as? String, !slug.isEmpty else {
                return
            }
            let status = OrderStatus(rawValue: slug)
            returnDict[status] = totalResult[Constants.totalKey]?.value as? Int ?? 0
        })
        return returnDict
    }
}


private extension ReportOrderTotalsMapper{
    enum Constants {
        static let slugKey: String  = "slug"
        static let totalKey: String = "total"
    }
}


/// The report endpoint returns the totals document within a `data` key. This entity
/// allows us to do parse all the things with JSONDecoder.
///
private struct ReportOrderTotalsEnvelope: Decodable {
    let totals: [[String: AnyDecodable]]
    private enum CodingKeys: String, CodingKey {
        case totals = "data"
    }
}
