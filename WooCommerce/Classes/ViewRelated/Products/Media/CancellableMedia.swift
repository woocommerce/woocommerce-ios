import Yosemite

/// A wrapper of `Media` that includes a cancellable task that is set when the media has an async cancellable task.
/// Note: this is an `NSObject` class instead of a struct because it has to conform to `WPMediaAsset` protocol defined in
/// Objective-C.
///
final class CancellableMedia: NSObject {
    var cancellableTask: Cancellable?

    let media: Media

    init(media: Media) {
        self.media = media
    }
}
