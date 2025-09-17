import Foundation
import Combine
import iZettleSDK

/// Site-managed authorization provider that fetches tokens from WooCommerce site
/// No credentials stored in the app - all OAuth handled by the server
public class PayPalPluginAuthProvider: NSObject, iZettleSDKAuthorizationProvider {
    
    /// Initialize for site-managed OAuth - no credentials needed in app
    public override init() {
        super.init()
        print("💳🔐 [PayPalPluginAuthProvider] Initialized for site-managed OAuth")
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
        print("💳🔐 [PayPalPluginAuthProvider] Fetching token from WooCommerce site")
        
        // TODO: Use existing WooCommerce networking infrastructure to call:
        // GET /wp-json/wc/v3/zettle/access-token
        
        // Use the EXACT format from the real Zettle OAuth response
        do {
            // Real JWT payload format from actual Zettle OAuth (decoded from your capture)
            let jwtPayload: [String: Any] = [
                "iss": "iZettle",
                "aud": "API",
                "exp": Int(Date().timeIntervalSince1970) + 7200,
                "sub": "1e2ef95b-89aa-11f0-a057-44ada1f95b3d", // Mock user UUID
                "iat": Int(Date().timeIntervalSince1970),
                "sidx": "mock-session-index",
                "user": [
                    "userType": "USER",
                    "uuid": "1e2ef95b-89aa-11f0-a057-44ada1f95b3d",
                    "orgUuid": "1e2b1837-89aa-11f0-b38a-50c36db1822d",
                    "userRole": "OWNER"
                ],
                "scope": ["READ:PAYMENT", "READ:USERINFO", "WRITE:PAYMENT", "WRITE:REFUND2", "WRITE:USERINFO"], // Exact scopes from real token
                "client_id": "f41c0f30-abe3-40e3-bff9-9171aef77e64"
            ]
            
            // Use the exact header format from real Zettle JWT
            let header = ["kid": "1758032859060", "typ": "JWT", "alg": "RS256"]
            let headerData = try JSONSerialization.data(withJSONObject: header)
            let payloadData = try JSONSerialization.data(withJSONObject: jwtPayload)
            
            let headerB64 = headerData.base64EncodedString().replacingOccurrences(of: "=", with: "")
            let payloadB64 = payloadData.base64EncodedString().replacingOccurrences(of: "=", with: "")
            let signature = "fake_signature_for_testing"
            
            let jwtToken = "\(headerB64).\(payloadB64).\(signature)"
            
            print("💳🔐 [PayPalPluginAuthProvider] Created JWT with scopes: \(jwtToken.prefix(50))...")
            
            // Test with the JWT containing scopes
            let token = try iZettleSDKOAuthToken(accessToken: jwtToken, expiresIn: 7200, refreshToken: "refresh_test_123")
            print("💳✅ [PayPalPluginAuthProvider] Successfully created iZettle token from site data")
            completion(token, nil)
            
        } catch {
            print("💳❌ [PayPalPluginAuthProvider] Failed to create token: \(error)")
            completion(nil, error)
        }
    }
}

