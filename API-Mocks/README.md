We use [WireMock](https://wiremock.org/) to run a mock API servers that UI tests can connect to.

The tool expects responses and resources in `__files/` and `mappings/` folders.
Those folders are located in the APIMOcks Swift package (`../Modules/Sources/APIMocks/Resources/`).

The Swift package exists to allow tests to access the raw responses to compare them with what's on screen.

The resources are in the package folder because Swift Package Manager does not allow packages to reference files in parent folders.

WireMock is able to access them because we pass their path using the `--root-dir` parameter upon starting the server.
