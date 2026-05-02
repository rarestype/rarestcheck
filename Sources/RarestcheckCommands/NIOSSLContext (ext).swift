import NIOSSL

extension NIOSSLContext {
    static var clientDefault: Self {
        get throws {
            var configuration: TLSConfiguration = .makeClientConfiguration()
            ;   configuration.applicationProtocols = ["h2"]
            return try .init(configuration: configuration)
        }
    }
}
