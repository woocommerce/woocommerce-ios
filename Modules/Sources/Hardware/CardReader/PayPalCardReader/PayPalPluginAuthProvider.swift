import Foundation
import Combine
import iZettleSDK

struct ZettleTokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String?
    let scope: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
    }
}

public struct WooCredentials {
    let username: String
    let password: String
}

/// Site-managed authorization provider that fetches tokens from WooCommerce site
/// No credentials stored in the app - all OAuth handled by the server
public class PayPalPluginAuthProvider: NSObject, iZettleSDKAuthorizationProvider {
    
    private let siteURL: String?
    private let credentials: WooCredentials?
    
    /// Initialize for site-managed OAuth with site credentials
    public init(siteURL: String, credentials: WooCredentials) {
        self.siteURL = siteURL
        self.credentials = credentials
        super.init()
        print("💳🔐 [PayPalPluginAuthProvider] Initialized for site-managed OAuth with site: \(siteURL)")
    }
    
    /// Initialize for site-managed OAuth - no credentials needed in app (fallback)
    public override init() {
        self.siteURL = nil
        self.credentials = nil
        super.init()
        print("💳🔐 [PayPalPluginAuthProvider] Initialized for site-managed OAuth (no credentials)")
    }
    
    // MARK: - iZettleSDKAuthorizationProvider Implementation
    
    /// Authorize account using stored plugin credentials
    /// This method is called by iZettle SDK when authentication is needed
    public func authorizeAccount(completion: @escaping iZettleAuthorizationCompletion) {
        print("💳🔐 [PayPalPluginAuthProvider] authorizeAccount called - using plugin credentials")
        
        // Generate access token using plugin's stored credentials
        generateAccessToken { [weak self] token, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("💳❌ [PayPalPluginAuthProvider] Authorization failed: \(error)")
                    completion(nil, error)
                } else if let token = token {
                    print("💳✅ [PayPalPluginAuthProvider] Authorization successful")
                    completion(token, nil)
                } else {
                    print("💳❌ [PayPalPluginAuthProvider] No token returned")
                    let error = NSError(domain: "PayPalPluginAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate access token"])
                    completion(nil, error)
                }
            }
        }
    }
    
    /// Verify account for refund operations using stored plugin credentials
    /// This method is called by iZettle SDK when refund verification is needed
    public func verifyAccount(uuid: UUID, completion: @escaping iZettleAuthorizationCompletion) {
        print("💳🔐 [PayPalPluginAuthProvider] verifyAccount called for UUID: \(uuid)")
        
        // For verification, we can reuse the same token generation process
        // The plugin credentials should work for both authorization and verification
        generateAccessToken { [weak self] token, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("💳❌ [PayPalPluginAuthProvider] Verification failed: \(error)")
                    completion(nil, error)
                } else if let token = token {
                    print("💳✅ [PayPalPluginAuthProvider] Verification successful")
                    completion(token, nil)
                } else {
                    print("💳❌ [PayPalPluginAuthProvider] No verification token returned")
                    let error = NSError(domain: "PayPalPluginAuth", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to generate verification token"])
                    completion(nil, error)
                }
            }
        }
    }
    
    // MARK: - Token Generation
    
    /// Generate access token by fetching from WooCommerce site
    private func generateAccessToken(completion: @escaping (iZettleSDKOAuthToken?, Error?) -> Void) {
        print("💳🔐 [PayPalPluginAuthProvider] Fetching real access token from plugin backend")
        
        fetchZettleTokenFromBackend { [weak self] result in
            switch result {
            case .success(let tokenData):
                do {
                    // Create iZettleSDKOAuthToken with real token from backend
                    let token = try iZettleSDKOAuthToken(
                        accessToken: tokenData.accessToken,
                        expiresIn: Int(TimeInterval(tokenData.expiresIn)),
                        refreshToken: tokenData.refreshToken ?? "no-refresh"
                    )
                    print("💳✅ [PayPalPluginAuthProvider] Successfully created iZettle token from backend")
                    completion(token, nil)
                } catch {
                    print("💳❌ [PayPalPluginAuthProvider] Failed to create iZettle token: \(error)")
                    completion(nil, error)
                }
                
            case .failure(let error):
                print("💳❌ [PayPalPluginAuthProvider] Failed to fetch token from backend: \(error)")
                completion(nil, error)
            }
        }
    }
    
    private func fetchZettleTokenFromBackend(completion: @escaping (Result<ZettleTokenResponse, Error>) -> Void) {
        guard let siteURL = siteURL, 
              let credentials = credentials else {
            completion(.failure(NSError(domain: "PayPalPluginAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing site URL or credentials"])))
            return
        }
        
        // Construct URL for Zettle access token endpoint
        let urlString = "\(siteURL)/wp-json/wc/v3/zettle/access-token"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "PayPalPluginAuth", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authentication headers
        let authString = "\(credentials.username):\(credentials.password)"
        let authData = authString.data(using: .utf8)!
        let base64AuthString = authData.base64EncodedString()
        request.setValue("Basic \(base64AuthString)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("💳🌐 [PayPalPluginAuthProvider] Calling: \(urlString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "PayPalPluginAuth", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Check HTTP status
            if let httpResponse = response as? HTTPURLResponse {
                print("💳📡 [PayPalPluginAuthProvider] Response status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("💳❌ [PayPalPluginAuthProvider] Error response: \(responseString)")
                    }
                    completion(.failure(NSError(domain: "PayPalPluginAuth", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])))
                    return
                }
            }
            
            do {
                let tokenResponse = try JSONDecoder().decode(ZettleTokenResponse.self, from: data)
                print("💳✅ [PayPalPluginAuthProvider] Successfully decoded token response")
                completion(.success(tokenResponse))
            } catch {
                // Log the response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("💳❌ [PayPalPluginAuthProvider] Backend response: \(responseString)")
                }
                print("💳❌ [PayPalPluginAuthProvider] JSON decode error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
}

