import Foundation

/// Products Reports: Remote Endpoints for WC Analytics
///
public class ProductsReportsRemote: Remote {

    /// Fetch the products reports for a given site within the dates provided.
    ///
    /// - Parameters:
    ///   - siteID: The site ID.
    ///   - timeZone: The time zone to set the earliest/latest date strings in the API request.
    ///   - earliestDateToInclude: The earliest date to include in the results.
    ///   - latestDateToInclude: The latest date to include in the results.
    ///   - quantity: The number of intervals to fetch the order stats.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func loadTopProductsReport(for siteID: Int64,
                                      timeZone: TimeZone,
                                      earliestDateToInclude: Date,
                                      latestDateToInclude: Date,
                                      quantity: Int) async throws -> [ProductsReportItem] {
        let dateFormatter = DateFormatter.Defaults.iso8601WithoutTimeZone
        dateFormatter.timeZone = timeZone

        let parameters: [String: Any] = [
            ParameterKeys.after: dateFormatter.string(from: earliestDateToInclude),
            ParameterKeys.before: dateFormatter.string(from: latestDateToInclude),
            ParameterKeys.quantity: String(quantity),
            ParameterKeys.orderBy: ParameterValues.orderBy,
            ParameterKeys.order: ParameterValues.order,
            ParameterKeys.extendedInfo: ParameterValues.extendedInfo
        ]

        let request = JetpackRequest(wooApiVersion: .wcAnalytics,
                                     method: .get,
                                     siteID: siteID,
                                     path: Constants.path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = ProductsReportMapper()

        return try await enqueue(request, mapper: mapper)
    }
}


// MARK: - Constants!
//
private extension ProductsReportsRemote {
    enum Constants {
        static let path: String = "reports/products"
    }

    enum ParameterKeys {
        static let after        = "after"
        static let before       = "before"
        static let quantity     = "per_page"
        static let orderBy      = "orderby"
        static let order        = "order"
        static let extendedInfo = "extended_info"
    }

    enum ParameterValues {
        static let orderBy      = "items_sold"
        static let order        = "desc"
        static let extendedInfo = "true"
    }
}
