#if canImport(Cryptography)
import Cryptography
import GitHubAPI
import GitHubClient
import GitHubRSA
import UnixCalendar
import UnixTime

extension GitHub.Client<GitHub.App> {
    func iat(
        for owner: String,
        key: borrowing RSA.PrivateKey
    ) async throws -> GitHub.InstallationAccessToken {
        let issued: UnixAttosecond = .now()
        let claims: GitHub.WebTokenClaims = .init(
            iat: issued.second,
            iss: self.app.client
        )

        let signed: String = try key.jwt(signing: claims)
        let access: GitHub.AppInstallationAccessTokenResponse = try await self.connect {
            let installation: GitHub.Installation = try await $0.get(
                from: "/users/\(owner)/installation",
                with: .token(signed)
            )
            return try await $0.post(
                from: "/app/installations/\(installation.id)/access_tokens",
                with: .token(signed)
            )
        }

        return access.token
    }
}
#endif
