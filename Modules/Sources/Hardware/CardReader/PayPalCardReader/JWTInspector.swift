import Foundation

/// Simple JWT decoder for inspecting real Zettle tokens
struct JWTInspector {
    
    /// Decode and print JWT payload for analysis
    static func inspectToken(_ token: String) {
        print("🔍 [JWTInspector] Analyzing token: \(token.prefix(50))...")
        
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else {
            print("❌ [JWTInspector] Invalid JWT format - expected 3 parts, got \(parts.count)")
            return
        }
        
        let header = parts[0]
        let payload = parts[1]
        let signature = parts[2]
        
        print("🔍 [JWTInspector] Header: \(header)")
        print("🔍 [JWTInspector] Payload: \(payload)")
        print("🔍 [JWTInspector] Signature: \(signature.prefix(20))...")
        
        // Decode header
        if let headerData = base64UrlDecode(header),
           let headerJson = try? JSONSerialization.jsonObject(with: headerData) as? [String: Any] {
            print("🔍 [JWTInspector] Decoded Header:")
            for (key, value) in headerJson {
                print("  \(key): \(value)")
            }
        }
        
        // Decode payload
        if let payloadData = base64UrlDecode(payload),
           let payloadJson = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] {
            print("🔍 [JWTInspector] Decoded Payload:")
            for (key, value) in payloadJson {
                print("  \(key): \(value)")
            }
            
            // Look specifically for scope-related fields
            if let scopes = payloadJson["scope"] ?? payloadJson["scopes"] {
                print("🎯 [JWTInspector] FOUND SCOPES: \(scopes)")
            }
        }
    }
    
    /// Base64 URL decode (JWT uses URL-safe base64)
    private static func base64UrlDecode(_ input: String) -> Data? {
        var base64 = input
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if needed
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        
        return Data(base64Encoded: base64)
    }
}