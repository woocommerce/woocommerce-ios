import Testing
import Modules

@Test("Dummy test")
func salutation() async throws {
    #expect(DummyModule.sayHello() == "Hello, World!")
}
