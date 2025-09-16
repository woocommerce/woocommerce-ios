import Foundation
import Combine
import iZettleSDK

/// Custom PayPal authorization provider that reuses credentials from the WooCommerce PayPal Payments plugin
/// This eliminates the need for users to log in again since they're already authenticated with the plugin
public class PayPalPluginAuthProvider: NSObject, iZettleSDKAuthorizationProvider {
    
    private let clientId: String
    private let clientSecret: String
    private let merchantId: String
    private let isSandbox: Bool
    
    /// Initialize with credentials from the WooCommerce PayPal Payments plugin
    /// - Parameters:
    ///   - clientId: PayPal OAuth Client ID from plugin
    ///   - clientSecret: PayPal OAuth Client Secret from plugin  
    ///   - merchantId: Connected merchant ID from plugin
    ///   - isSandbox: Whether the merchant is using sandbox mode
    public init(clientId: String, clientSecret: String, merchantId: String, isSandbox: Bool) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.merchantId = merchantId
        self.isSandbox = isSandbox
        super.init()
        
        print("💳🔐 [PayPalPluginAuthProvider] Initialized with plugin credentials")
        print("💳🔐 [PayPalPluginAuthProvider] Client ID: \(clientId.prefix(8))...")
        print("💳🔐 [PayPalPluginAuthProvider] Merchant ID: \(merchantId)")
        print("💳🔐 [PayPalPluginAuthProvider] Sandbox: \(isSandbox)")
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
    
    /// Generate PayPal access token using stored client credentials
    /// This implements the OAuth 2.0 client credentials flow
    private func generateAccessToken(completion: @escaping (iZettleSDKOAuthToken?, Error?) -> Void) {
        print("💳🔐 [PayPalPluginAuthProvider] Generating access token using client credentials flow")
        
        // Use appropriate PayPal API endpoint based on sandbox mode
        let baseURL = isSandbox ? "https://api.sandbox.paypal.com" : "https://api.paypal.com"
        let tokenURL = URL(string: "\(baseURL)/v1/oauth2/token")!
        
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Set Authorization header with base64 encoded client credentials
        let credentials = "\(clientId):\(clientSecret)"
        let credentialsData = credentials.data(using: .utf8)!
        let base64Credentials = credentialsData.base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        
        // Request body for client credentials grant
        let bodyString = "grant_type=client_credentials&scope=https://uri.paypal.com/services/payments/payment"
        request.httpBody = bodyString.data(using: .utf8)
        
        print("💳🔐 [PayPalPluginAuthProvider] Making token request to: \(tokenURL)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("💳❌ [PayPalPluginAuthProvider] Network error: \(error)")
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                print("💳❌ [PayPalPluginAuthProvider] No data received")
                let error = NSError(domain: "PayPalPluginAuth", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data received from token endpoint"])
                completion(nil, error)
                return
            }
            
            do {
                // Parse the OAuth token response
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("💳🔐 [PayPalPluginAuthProvider] Token response received")
                    
                    // Create iZettleSDKOAuthToken from the response
                    let token = try iZettleSDKOAuthToken(data: data)
                    print("💳✅ [PayPalPluginAuthProvider] Successfully created iZettle OAuth token")
                    completion(token, nil)
                } else {
                    print("💳❌ [PayPalPluginAuthProvider] Invalid JSON response")
                    let error = NSError(domain: "PayPalPluginAuth", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response from token endpoint"])
                    completion(nil, error)
                }
            } catch {
                print("💳❌ [PayPalPluginAuthProvider] Failed to parse token response: \(error)")
                completion(nil, error)
            }
        }.resume()
    }
}

// MARK: - WordPress Plugin Integration

extension PayPalPluginAuthProvider {
    
    /// Factory method to create auth provider from WordPress plugin settings
    /// This method would be called from your WooCommerce site's PayPal plugin settings
    /// - Parameter pluginSettings: Settings data from the WooCommerce PayPal Payments plugin
    /// - Returns: Configured auth provider ready for use with iZettle SDK
    public static func fromPluginSettings(_ pluginSettings: [String: Any]) -> PayPalPluginAuthProvider? {
        guard let clientId = pluginSettings["client_id"] as? String,
              let clientSecret = pluginSettings["client_secret"] as? String,
              let merchantId = pluginSettings["merchant_id"] as? String else {
            print("💳❌ [PayPalPluginAuthProvider] Missing required plugin settings")
            return nil
        }
        
        let isSandbox = pluginSettings["sandbox_merchant"] as? Bool ?? false
        
        print("💳🔐 [PayPalPluginAuthProvider] Created from plugin settings successfully")
        return PayPalPluginAuthProvider(
            clientId: clientId,
            clientSecret: clientSecret, 
            merchantId: merchantId,
            isSandbox: isSandbox
        )
    }
}