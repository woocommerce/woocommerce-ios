import Foundation

public extension SystemStatus {
    /// Subtype for details about environment in system status.
    ///
    struct Environment {
        
    }
}

private extension SystemStatus.Environment {
    enum CodingKeys: String, CodingKey {
        case homeURL = "home_url"
        case siteURL = "site_url"
        case version
//        case 
    }
    
}
