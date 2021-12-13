import MapKit

final class MapsHelper {

    /// The method accept a string of the address info you already have, and open Apple Maps on that address if found.
    ///
    static func openAppleMaps(address: String?, completion: @escaping (Result<Void, MapsHelperError>) -> Void) {
        guard let address = address else {
            completion(.failure(.locationNotFound))
            return
        }
        CLGeocoder().geocodeAddressString(address) { (placemarksOptional, error) -> Void in
            guard let placemarks = placemarksOptional else {
                completion(.failure(.locationNotFound))
                return
            }
            DDLogInfo("First address found in Apple Maps: \(String(describing: placemarks.first))")
            if let location = placemarks.first?.location {
                let query = "?ll=\(location.coordinate.latitude),\(location.coordinate.longitude)"
                let path = "http://maps.apple.com/" + query
                if let url = URL(string: path) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    completion(.success(()))
                } else {
                    completion(.failure(.constructURL))
                }
            } else {
                completion(.failure(.locationNotFound))
            }
        }
    }

    enum MapsHelperError: Error {
        // Could not construct url.
        case constructURL

        // Could not get a location from the geocode request.
        case locationNotFound
    }
}
