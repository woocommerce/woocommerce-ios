// Generated using Sourcery 1.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import Yosemite
import Networking

extension ProductReviewFromNoteParcel {
    /// Returns a "ready to use" type filled with fake values.
    ///
    public static func fake() -> ProductReviewFromNoteParcel {
        .init(
            note: .fake(),
            review: .fake(),
            product: .fake()
        )
    }
}
