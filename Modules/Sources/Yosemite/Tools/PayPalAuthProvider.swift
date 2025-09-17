import Foundation
import Hardware
import Networking
import iZettleSDK


/// PayPal authentication provider that uses Yosemite networking to fetch Zettle tokens
/// This provider handles the site-managed OAuth flow for PayPal card readers
public final class PayPalAuthProvider: NSObject, iZettleSDKAuthorizationProvider {
    
    private let siteID: Int64
    private let paypalRemote: PayPalRemote
    
    public init(siteID: Int64, paypalRemote: PayPalRemote) {
        self.siteID = siteID
        self.paypalRemote = paypalRemote
        super.init()
        print("💳🔐 [PayPalAuthProvider] Initialized for site: \(siteID)")
    }
    
    // MARK: - iZettleSDKAuthorizationProvider Implementation
    
    /// Authorize account using stored plugin credentials
    /// This method is called by iZettle SDK when authentication is needed
    public func authorizeAccount(completion: @escaping iZettleAuthorizationCompletion) {
        print("💳🔐 [PayPalAuthProvider] authorizeAccount called - fetching from backend")
        
        fetchZettleToken { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let tokenData):
                    do {
                        let token = try iZettleSDKOAuthToken(
                            accessToken: tokenData.accessToken,
                            expiresIn: Int(TimeInterval(tokenData.expiresIn)),
                            refreshToken: tokenData.refreshToken ?? "no-refresh"
                        )
                        print("💳✅ [PayPalAuthProvider] Authorization successful")
                        completion(token, nil)
                    } catch {
                        print("💳❌ [PayPalAuthProvider] Failed to create iZettle token: \(error)")
                        completion(nil, error)
                    }
                    
                case .failure(let error):
                    print("💳❌ [PayPalAuthProvider] Authorization failed: \(error)")
                    completion(nil, error)
                }
            }
        }
    }
    
    /// Verify account for refund operations using stored plugin credentials
    /// This method is called by iZettle SDK when refund verification is needed
    public func verifyAccount(uuid: UUID, completion: @escaping iZettleAuthorizationCompletion) {
        print("💳🔐 [PayPalAuthProvider] verifyAccount called for UUID: \(uuid)")
        
        // For verification, we can reuse the same token fetching process
        fetchZettleToken { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let tokenData):
                    do {
                        let token = try iZettleSDKOAuthToken(
                            accessToken: tokenData.accessToken,
                            expiresIn: Int(TimeInterval(tokenData.expiresIn)),
                            refreshToken: tokenData.refreshToken ?? "no-refresh"
                        )
                        print("💳✅ [PayPalAuthProvider] Verification successful")
                        completion(token, nil)
                    } catch {
                        print("💳❌ [PayPalAuthProvider] Failed to create verification token: \(error)")
                        completion(nil, error)
                    }
                    
                case .failure(let error):
                    print("💳❌ [PayPalAuthProvider] Verification failed: \(error)")
                    completion(nil, error)
                }
            }
        }
    }
    
    // MARK: - Token Fetching
    
    private func fetchZettleToken(completion: @escaping (Result<ZettleTokenResponse, Error>) -> Void) {
        print("💳🌐 [PayPalAuthProvider] Fetching Zettle token from backend for site \(siteID)")
        
        paypalRemote.fetchZettleAccessToken(for: siteID) { result in
            switch result {
            case .success(let tokenResponse):
                print("💳✅ [PayPalAuthProvider] Successfully fetched Zettle token from backend")
                completion(.success(tokenResponse))
                
            case .failure(let error):
                print("💳❌ [PayPalAuthProvider] Failed to fetch Zettle token: \(error)")
                completion(.failure(error))
            }
        }
    }
}