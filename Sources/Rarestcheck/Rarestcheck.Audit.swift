import ArgumentParser
import GitHubAPI
import System_ArgumentParser
import SystemIO
import RarestcheckCommands

extension Rarestcheck {
    struct Audit {
        @Argument(
            help: ""
        ) var inputs: FilePath

        @Option(
            name: [.customLong("filter"), .customShort("t")],
            help: "topic filter"
        ) var filter: String?

        @Option(
            name: [.customLong("workspace"), .customShort("w")],
            help: "workspace directory"
        ) var workspace: FilePath.Directory = "repositories"
    }
}
extension Rarestcheck.Audit: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "audit",
        )
    }
}
extension Rarestcheck.Audit: RarestcheckCommand {
    func run(token: String, repo: GitHub.Repo) throws -> Bool {
        try self.workspace.create()
        let script: FilePath = try .current / "Scripts" / "Check"
        let process: SystemProcess = try .init(
            command: "/bin/bash",
            arguments: ["\(script)", repo.owner.login, repo.name],
            in: self.workspace,
            with: .inherit {
                $0["GH_TOKEN"] = token
            }
        )
        switch process.status() {
        case .success:
            print("💞 repository \(accent: repo.name) contains no insecure email addresses!")
            return true
        case .failure:
            print("❗ repository \(accent: repo.name) contains insecure email addresses!!!")
            return false
        }
    }
}
