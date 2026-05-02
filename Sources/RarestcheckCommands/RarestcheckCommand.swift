#if canImport(Cryptography)
import Cryptography
import ArgumentParser
import GitHubAPI
import System_ArgumentParser
import SystemIO
import URI

public protocol RarestcheckCommand {
    var inputs: FilePath { get }
    var filter: String? { get }

    func run(token: String, repo: GitHub.Repo) async throws -> Bool
}
extension RarestcheckCommand {
    public func run() async throws {
        let app: GitHub.App = .init(
            nil,
            client: try Environment["AUTOMATION_APP_CLIENT"],
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

        let pat: GitHub.PersonalAccessToken? = try? Environment["AUTOMATION_PAT_FALLBACK"]

        var failedScan: Bool = false
        var failedValidation: Bool = false

        for (owner, pattern): (String, Rarestcheck.InputPattern) in try self.namespaces {
            print("💖 processing namespace: \(bold: owner)...")

            let authorization: GitHub.ClientAuthorization
            do {
                let iat: GitHub.InstallationAccessToken = try await api.iat(
                    for: owner,
                    key: key
                )
                authorization = .token(iat)
            } catch {
                if  let pat: GitHub.PersonalAccessToken {
                    print(
                        """
                        \(bold: "warning:") GitHub app not installed under namespace \
                        \(bold: owner)
                        \(accent: "note:") using PAT fallback instead
                        """
                    )
                    authorization = .token(pat)
                } else {
                    print(
                        """
                        \(fail: "error:") GitHub app not installed under namespace \
                        \(bold: owner)
                        """
                    )
                    failedScan = true
                    continue
                }
            }

            guard case .token(let token) = authorization else {
                print("unsupported auth method")
                throw ExitCode.failure
            }

            /// maximum crawl width supported by GitHub
            let width: Int = 100
            let repos: [GitHub.Repo]

            switch pattern {
            case .all:
                repos = try await api.connect {
                    var results: [GitHub.Repo] = []
                    for page: Int in 1... {
                        var q: String = "org:\(owner) fork:false"
                        if  let topic: String = self.filter {
                            q += " topic:\(topic)"
                        }
                        let query: URI.Query = [
                            "q": q,
                            "per_page": "\(width)",
                            "page": "\(page)"
                        ]
                        let search: GitHub.SearchRepositoriesResponse = try await $0.get(
                            from: "/search/repositories\(query)",
                            with: authorization
                        )
                        // no better way to filter, as GitHub API does not support logical OR
                        for item: GitHub.Repo in search.items
                            where item.visibility == .public || !item.archived {
                            results.append(item)
                        }
                        if  search.items.count < width {
                            break
                        }
                    }
                    results.sort { $0.name < $1.name }
                    return results
                }
            case .only(let selected):
                repos = try await api.connect {
                    var results: [GitHub.Repo] = []
                    for repo: String in selected {
                        let repo: GitHub.Repo = try await $0.get(
                            from: "/repos/\(owner)/\(repo)",
                            with: authorization
                        )
                        if  let topic: String = self.filter, repo.topics.contains(topic) {
                            results.append(repo)
                        } else if case nil = self.filter {
                            results.append(repo)
                        }
                    }
                    return results
                }
            }

            for repo: GitHub.Repo in repos {
                guard try await self.run(token: token, repo: repo) else {
                    failedValidation = true
                    continue
                }
            }
        }

        if  failedValidation {
            print(
                """
                One or more repositories contains insecure emails!
                please create a mailmap file, then run

                    git filter-repo --mailmap ../../.mailmap
                    git filter-repo --path .mailmap --invert-paths
                    git remote add origin <url>
                    git push origin --force --all
                    git push origin --force --tags
                """
            )
            throw ExitCode.failure
        }

        if  failedScan {
            throw ExitCode.failure
        }
    }
}
extension RarestcheckCommand {
    private var namespaces: [String: Rarestcheck.InputPattern] {
        get throws {
            var namespaces: [String: Rarestcheck.InputPattern] = [:]
            try self.inputs.readLines { (line: Substring) in
                switch line.first {
                case nil:
                    return
                case "#"?:
                    return
                case _?:
                    break
                }

                guard let slash: String.Index = line.firstIndex(of: "/") else {
                    throw Rarestcheck.InputPatternError.malformed(line)
                }
                /// we expect these strings to be small, so copy them to liberate them from
                /// their original content buffer
                let owner: String = String.init(line[..<slash])
                let repo: Substring = line[line.index(after: slash)...]
                if  repo == "*" {
                    namespaces[owner] = .all
                    return
                } else if repo.isEmpty {
                    throw Rarestcheck.InputPatternError.malformed(line)
                }
                try {
                    switch consume $0 {
                    case .only(var repos):
                        repos.append(String.init(repo))
                        $0 = .only(repos)

                    case let incompatible:
                        $0 = incompatible
                        throw Rarestcheck.InputPatternError.redundant(line)
                    }

                } (&namespaces[owner, default: .only([])])
            }
            return namespaces
        }
    }
}

#else
import ArgumentParser

protocol RarestcheckCommand {}
extension RarestcheckCommand {
    func run() throws { throw ExitCode.failure }
}
#endif
