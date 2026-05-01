import Foundation
import SwiftUI
import protocol WooAIAssistant.AssistantExternalViewProviding

/// The trunk protocol surface is empty: cards still render through the module's fallback layout
/// until D4 (`Modules/Sources/WooAIAssistant/Cards/`) supplies real renderers. The adaptor exists so
/// the dependency factory has a real conformer it can pass through.
struct AIAssistantExternalViewsAdaptor: AssistantExternalViewProviding {

    init() {}
}
