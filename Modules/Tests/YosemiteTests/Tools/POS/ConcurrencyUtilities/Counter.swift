/// A simple counter actor to track increments in a thread-safe manner.
actor Counter {
    var value = 0

    func increment() {
        value += 1
    }
}
