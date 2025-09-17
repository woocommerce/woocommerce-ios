import Foundation
import Hardware
import Networking

/// PayPal-specific implementation of CommonReaderConfigProviding
/// This provider handles PayPal/Zettle OAuth token fetching but doesn't need location management like Stripe
public final class PayPalReaderConfigProvider: CommonReaderConfigProviding {
    
    private let siteID: Int64?
    private let paypalRemote: PayPalRemote?

    public init(siteID: Int64? = nil, network: Network? = nil) {
        self.siteID = siteID
        guard let network else {
            paypalRemote = nil
            return
        }
        self.paypalRemote = PayPalRemote(network: network)
        print("💳🔧 [PayPalReaderConfigProvider] Initialized for site: \(siteID)")
    }
    
    // MARK: - CardReaderRemoteConfigLoading Implementation
    
    /// PayPal creates its own network connection and doesn't need external context
    /// This method is required by CommonReaderConfigProviding but is a no-op for PayPal
    public func setContext(siteID: Int64, remote: CardReaderCapableRemote) {
        print("💳ℹ️ [PayPalReaderConfigProvider] setContext called - PayPal uses its own network, ignoring")
    }
    
    // MARK: - CardReaderConfigProvider Implementation
    
    /// Fetch Zettle access token for PayPal card reader authentication
    public func fetchToken(completion: @escaping(Result<String, Error>) -> Void) {
        print("💳🌐 [PayPalReaderConfigProvider] Fetching Zettle access token")
        guard let paypalRemote else {
            print("💳❌ [PayPalReaderConfigProvider] PayPalRemote is nil")
            completion(.failure(PayPalReaderConfigProviderError.noPayPalRemote))
            return
        }
        guard let siteID else {
            print("💳❌ [PayPalReaderConfigProvider] no siteID")
            completion(.failure(PayPalReaderConfigProviderError.noSiteID))
            return
        }
        paypalRemote.fetchZettleAccessToken(for: siteID) { result in
            switch result {
            case .success(let tokenResponse):
                print("💳✅ [PayPalReaderConfigProvider] Successfully fetched token")
                completion(.success(tokenResponse.accessToken))
                
            case .failure(let error):
                print("💳❌ [PayPalReaderConfigProvider] Failed to fetch token: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    /// PayPal/Zettle doesn't require location management like Stripe
    /// Return a placeholder value to satisfy the protocol
    public func fetchDefaultLocationID(completion: @escaping(Result<String, Error>) -> Void) {
        print("💳ℹ️ [PayPalReaderConfigProvider] PayPal doesn't require location ID - returning placeholder")
        completion(.success("paypal-default"))
    }
}

enum PayPalReaderConfigProviderError: Error {
    case noSiteID
    case noPayPalRemote
}
