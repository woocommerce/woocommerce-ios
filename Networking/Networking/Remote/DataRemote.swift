import Foundation

/// Data Remote Endpoints.
public final class DataRemote: Remote {

    /// Loads all the countries.
    /// - Parameters:
    ///   - siteID: Remote ID of the site that owns the countries.
    ///   - completion: Closure to be executed upon completion.
    public func loadCountries(siteID: Int64, completion: @escaping (Result<[Country], Error>) -> Void) {
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: Path.countries)
        let mapper = CountryListMapper()
        enqueue(request, mapper: mapper, completion: completion)
    }
}

// MARK: Constant
private extension DataRemote {
    enum Path {
        static let countries = "data/countries"
    }
}
