import Foundation
import Networking
import Codegen

public struct JustInTimeMessage: GeneratedFakeable, GeneratedCopiable, Equatable {
    /// Site Identifier
    ///
    public let siteID: Int64

    /// JITM id, e.g. `woomobile_ipp_barcode_users`. Identifies a message.
    ///
    public let messageID: String

    /// JITM feature class, groups JITMs by area, e.g. `woomobile_ipp`. JITMs are dismissed by feature class.
    ///
    public let featureClass: String

    /// The short user-displayed title of the JITM
    ///
    public let title: String

    /// The longer user-displayed detail of the JITM
    ///
    public let detail: String

    /// The button text of the Call to Action for the JITM
    ///
    public let buttonTitle: String

    /// The button link of the Call to Action for the JITM
    ///
    public let url: String

    public init(siteID: Int64,
                messageID: String,
                featureClass: String,
                title: String,
                detail: String,
                buttonTitle: String,
                url: String) {
        self.siteID = siteID
        self.messageID = messageID
        self.featureClass = featureClass
        self.title = title
        self.detail = detail
        self.buttonTitle = buttonTitle
        self.url = url
    }

    init(message: Networking.JustInTimeMessage) {
        self.init(siteID: message.siteID,
                  messageID: message.messageID,
                  featureClass: message.featureClass,
                  title: message.content.message,
                  detail: message.content.description,
                  buttonTitle: message.cta.message,
                  url: message.cta.link)
    }
}
