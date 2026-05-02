import GitHubAPI
import JSON

extension GitHub {
    struct SearchRepositoriesResponse {
        let items: [Repo]
    }
}
extension GitHub.SearchRepositoriesResponse: JSONObjectDecodable {
    enum CodingKey: String, Sendable {
        /// this cannot be used for pagination
        case incomplete_results
        case items
    }

    init(json: JSON.ObjectDecoder<CodingKey>) throws {
        self.init(
            items: try json[.items].decode()
        )
    }
}
