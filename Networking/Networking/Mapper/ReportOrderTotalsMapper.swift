import Foundation


/// Mapper: Order totals report
///
struct ReportOrderTotalsMapper: Mapper {

    /// (Attempts) to extract order totals report from a given JSON Encoded response.
    ///
    func map(response: Data) throws -> [String: Any] {
        let totalsArray = try JSONDecoder().decode(ReportOrderTotalsEnvelope.self, from: response).totals
        var returnDict = [OrderStatusKey: Int]()
        var returnArray = [OrderStatus]()
        totalsArray.forEach({ (totalResult) in
            guard let name = totalResult[Constants.nameKey]?.value as? String, !name.isEmpty else {
                return
            }

            guard let slug = totalResult[Constants.slugKey]?.value as? String, !slug.isEmpty else {
                return
            }

            let status = OrderStatusKey(rawValue: slug)

            let orderStatus = OrderStatus(name: name, slug: slug)
            returnArray.append(orderStatus)

            returnDict[status] = totalResult[Constants.totalKey]?.value as? Int ?? 0
        })

        let allItems: [String: Any] = [
            Constants.reportKey: returnDict, // [OrderStatusKey: Int]
            Constants.statusKey: returnArray // [OrderStatus]
        ]
        
        return allItems
    }
}


private extension ReportOrderTotalsMapper {
    enum Constants {
        static let nameKey = "name"
        static let slugKey  = "slug"
        static let totalKey = "total"
        static let reportKey = "report"
        static let statusKey = "status"
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
