import Foundation
import UIKit
import MapKit
import CoreLocation
import NetworkingCore

/// Helper class to handle opening addresses in Maps apps.
final class OrderDetailsMapLauncher {
    static func openAddress(_ address: Address, from viewController: UIViewController) {
        // Use custom URL scheme approach directly for better control and reliability
        openWithCustomURLSchemes(address: address, from: viewController)
    }

    /// Opens address using custom URL schemes with app selection
    private static func openWithCustomURLSchemes(address: Address, from viewController: UIViewController) {
        let addressString = formatAddressForMaps(address)

        let appleURL = createAppleMapsURL(from: addressString)

        // Checks availability for each app explicitly.
        var availableOptions: [(URL, String)] = []

        if let appleURL = appleURL, UIApplication.shared.canOpenURL(appleURL) {
            availableOptions.append((appleURL, "Apple Maps"))
        }

        // Tries to find an available Google Maps URL
        if let googleURL = findAvailableGoogleMapsURL(for: addressString) {
            availableOptions.append((googleURL, "Google Maps"))
        }

        guard !availableOptions.isEmpty else {
            // Fallback to web-based maps if no apps are available
            if let webURL = createWebMapsURL(from: addressString) {
                UIApplication.shared.open(webURL)
            }
            return
        }

        if availableOptions.count == 1 {
            // Only one option available, open directly
            UIApplication.shared.open(availableOptions[0].0)
        } else {
            // Multiple options available, show action sheet
            showActionSheet(options: availableOptions, from: viewController)
        }
    }

    private static func formatAddressForMaps(_ address: Address) -> String {
        return [
            address.address1,
            address.address2,
            address.city,
            address.state,
            address.postcode,
            address.country
        ].compactMap { $0?.isEmpty == false ? $0 : nil }.joined(separator: ", ")
    }

    private static func createAppleMapsURL(from addressString: String) -> URL? {
        guard let encodedAddress = addressString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "http://maps.apple.com/?q=\(encodedAddress)")
    }

    private static func createGoogleMapsURL(from addressString: String) -> URL? {
        guard let encodedAddress = addressString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        // Try the newer Google Maps URL scheme first
        return URL(string: "googlemaps://?q=\(encodedAddress)")
    }

    private static func findAvailableGoogleMapsURL(for addressString: String) -> URL? {
        guard let encodedAddress = addressString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }

        // Try different Google Maps URL schemes in order of preference
        let googleMapsSchemes = [
            "googlemaps://?q=\(encodedAddress)",     // Modern Google Maps
            "comgooglemaps://?q=\(encodedAddress)",  // Legacy Google Maps
            "gmap://?q=\(encodedAddress)"           // Alternative scheme
        ]

        for schemeString in googleMapsSchemes {
            if let url = URL(string: schemeString), UIApplication.shared.canOpenURL(url) {
                return url
            }
        }

        return nil
    }

    private static func createWebMapsURL(from addressString: String) -> URL? {
        guard let encodedAddress = addressString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "https://maps.google.com/maps?q=\(encodedAddress)")
    }

    private static func showActionSheet(options: [(URL, String)], from viewController: UIViewController) {
        let alertController = UIAlertController(
            title: NSLocalizedString("Open Address", comment: "Title for the action sheet to open address in maps"),
            message: nil,
            preferredStyle: .actionSheet
        )

        for (url, name) in options {
            let action = UIAlertAction(title: name, style: .default) { _ in
                UIApplication.shared.open(url)
            }
            alertController.addAction(action)
        }

        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Cancel", comment: "Cancel action for opening address in maps"),
            style: .cancel
        )
        alertController.addAction(cancelAction)

        // For iPad support
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        viewController.present(alertController, animated: true)
    }
}
