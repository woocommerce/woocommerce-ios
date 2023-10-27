import Foundation
import WordPressKit

struct SiteAddressViewModel {
    private let isSiteDiscovery: Bool
    private let xmlrpcFacade: WordPressXMLRPCAPIFacade
    private let tracker = AuthenticatorAnalyticsTracker.shared
    private let authenticationDelegate: WordPressAuthenticatorDelegate
    private var loginFields: LoginFields

    init(isSiteDiscovery: Bool,
         xmlrpcFacade: WordPressXMLRPCAPIFacade,
         authenticationDelegate: WordPressAuthenticatorDelegate,
         loginFields: LoginFields
    ) {
        self.isSiteDiscovery = isSiteDiscovery
        self.xmlrpcFacade = xmlrpcFacade
        self.authenticationDelegate = authenticationDelegate
        self.loginFields = loginFields
    }

    enum GuessXMLRPCURLResult {
        case success
        case error(NSError, String?)
        case troubleshootSite
        case loading(Bool)
        case customUI(UIViewController)
    }

    func guessXMLRPCURL(
        for siteAddress: String,
        completion: @escaping (GuessXMLRPCURLResult) -> ()
    ) {
        let facade = WordPressXMLRPCAPIFacade()
        facade.guessXMLRPCURL(forSite: siteAddress, success: { url in
            // Success! We now know that we have a valid XML-RPC endpoint.
            // At this point, we do NOT know if this is a WP.com site or a self-hosted site.
            if let url = url {
                self.loginFields.meta.xmlrpcURL = url as NSURL
            }

            completion(.success)

            }, failure: { error in
                guard let error = error else {
                    return
                }
                // Intentionally log the attempted address on failures.
                // It's not guaranteed to be included in the error object depending on the error.
                WPAuthenticatorLogInfo("Error attempting to connect to site address: \(self.loginFields.siteAddress)")
                WPAuthenticatorLogError(error.localizedDescription)

                self.tracker.track(failure: .loginFailedToGuessXMLRPC)


                completion(.loading(false))

                guard self.isSiteDiscovery == false else {
                    completion(.troubleshootSite)
                    return
                }

                let err = self.originalErrorOrError(error: error as NSError)
                self.handleGuessXMLRPCURLError(error: err, completion: completion)
        })
    }

    private func handleGuessXMLRPCURLError(
        error: NSError,
        completion: @escaping (GuessXMLRPCURLResult) -> ()
    ) {
        let errorMessage: String?
        if let xmlrpcValidatorError = error as? WordPressOrgXMLRPCValidatorError {
            errorMessage = xmlrpcValidatorError.localizedDescription
        } else if (error.domain == NSURLErrorDomain && error.code == NSURLErrorCannotFindHost) ||
                  (error.domain == NSURLErrorDomain && error.code == NSURLErrorNetworkConnectionLost) {
            errorMessage = NSLocalizedString("The site at this address is not a WordPress site. For us to connect to it, the site must use WordPress.", comment: "Error message shown when a URL does not point to an existing site.")
        } else {
            errorMessage = nil
        }

        if self.authenticationDelegate.shouldHandleError(error) {
            self.authenticationDelegate.handleError(error) { customUI in
                completion(.customUI(customUI))
            }
            if let message = errorMessage {
                self.tracker.track(failure: message)
            }
            return
        }

        completion(.error(error, errorMessage))
    }

    private func originalErrorOrError(error: NSError) -> NSError {
        guard let err = error.userInfo[XMLRPCOriginalErrorKey] as? NSError else {
            return error
        }

        return err
    }
}
