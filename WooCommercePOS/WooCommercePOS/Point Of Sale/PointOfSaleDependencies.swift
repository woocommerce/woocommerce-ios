import Foundation
import protocol WooFoundation.Analytics

public class PointOfSaleDependencies {
    let analytics: Analytics

    public init(analytics: Analytics) {
        self.analytics = analytics
    }
}
