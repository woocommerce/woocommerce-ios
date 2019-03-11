import Foundation


/// Mapper: Order totals report
///
struct ReportOrderTotalsMapper: Mapper {

    /// (Attempts) to extract order totals report from a given JSON Encoded response.
    ///
    func map(response: Data) throws -> [OrderStatusKey: Int] {
        let totalsArray = try JSONDecoder().decode(ReportOrderTotalsEnvelope.self, from: response).totals
        var returnDict = [OrderStatusKey: Int]()
        totalsArray.forEach({ (totalResult) in
            guard let slug = totalResult[Constants.slugKey]?.value as? String, !slug.isEmpty else {
                return
            }
            let status = OrderStatusKey(rawValue: slug)
            returnDict[status] = totalResult[Constants.totalKey]?.value as? Int ?? 0
        })
        return returnDict
    }
}


private extension ReportOrderTotalsMapper {
    enum Constants {
        static let slugKey  = "slug"
        static let totalKey = "total"
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
