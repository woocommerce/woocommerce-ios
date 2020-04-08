import Yosemite

/// A wrapper of `Media` that includes a cancellable task that is set when the media has an async cancellable task.
///
final class CancellableMedia: NSObject {
    var cancellableTask: Cancellable?

    let media: Media

    init(media: Media) {
        self.media = media
    }
}
