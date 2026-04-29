import ArgumentParser
import Cryptography
import GitHubAPI
import System_ArgumentParser
import SystemIO

extension Rarestcheck {
    struct IAT {
        @Argument(
            help: "where the app is installed"
        ) var target: String

        @Option(
            name: [.customLong("client")],
            help: "the app’s client identifier"
        ) var client: String?
    }
}
extension Rarestcheck.IAT: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "iat",
        )
    }

    func run() async throws {
        let app: GitHub.App = .init(
            nil,
            client: try self.client ?? Environment["AUTOMATION_APP_CLIENT"],
            secret: try Environment["AUTOMATION_APP_SECRET"]
        )
        let key: RSA.PrivateKey = try .init(
            pem: try Environment["AUTOMATION_APP_KEY"]
        )
        let api: GitHub.Client<GitHub.App> = .rest(
            app: app,
            niossl: try .clientDefault,
            on: .singleton,
            as: "rarestcheck"
        )
        let iat: GitHub.InstallationAccessToken = try await api.iat(
            for: self.target,
            key: key
        )

        print(iat)
    }
}
