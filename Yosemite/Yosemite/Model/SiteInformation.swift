import Foundation
import Networking

/// Represents system information for a site
public struct SiteInformation {
    /// The site ID
    public let siteID: Int64
    
    /// The system information for the site
    public let systemInformation: SystemInformation?
    
    public init(siteID: Int64, systemInformation: SystemInformation?) {
        self.siteID = siteID
        self.systemInformation = systemInformation
    }
}
