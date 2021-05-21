import Foundation


/// Reports: Remote Endpoints
///
public class ReportRemote: Remote {

    /// Retrieves an orders totals report (for all known order statuses)
    ///
    public func loadOrdersTotals(for siteID: Int64, completion: @escaping (Result<[OrderStatus], Error>) -> Void) {
        let path = Constants.orderTotalsPath
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: nil)
        let mapper = ReportOrderTotalsMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants!
//
private extension ReportRemote {
    enum Constants {
        static let orderTotalsPath = "reports/orders/totals"
    }
}
