import ArgumentParser
import GitHubAPI
import System_ArgumentParser
import SystemAsync
import SystemIO
import RarestcheckCommands

extension Rarestcheck {
    struct Sync {
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
        ) var workspace: FilePath.Directory = "workspace"

        @Flag(
            name: [.customLong("push"), .customShort("f")],
            help: "whether to push changes"
        ) var push: Bool = false
    }
}
extension Rarestcheck.Sync: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "sync",
        )
    }
}
extension Rarestcheck.Sync: RarestcheckCommand {
    func run(on repo: GitHub.Repo) async throws -> Bool {
        try self.workspace.create()
        let clone: FilePath.Directory = self.workspace / repo.name
        if try !clone.exists {
            let process: SystemProcess = try .init(
                command: "gh",
                arguments: [
                    "repo",
                    "clone",
                    "\(repo.owner.login)/\(repo.name)",
                    "--",
                    "--quiet"
                ],
                in: self.workspace
            )
            try process()
        }

        try await self.vacuumBadges(repo: repo, clone: clone)

        let root: FilePath.Directory = try .current
        let templates: FilePath.Directory = root / "Templates"
        let script: FilePath = root / "Scripts" / "Sync"
        let readme: FilePath = clone / "README.md"
        if  try readme.exists {
            let labels: [(Substring, Substring?)] = try self.labelsInOrder(
                from: templates / "StatusLabels.txt"
            )

            let table: String = try await self.table(
                repo: repo,
                refs: try await self.refs(repo: repo, clone: clone),
                labels: labels
            )
            let lines: [Substring] = Rarestcheck.SyncReadme.apply(
                to: try readme.read().lines,
                id: "STATUS TABLE"
            ) {
                $0 = table.lines
            }

            try readme.overwrite(lines: lines)
        }

        let process: SystemProcess = try .init(
            command: "/bin/bash",
            arguments: [
                "\(script)", repo.owner.login, repo.name, "-t", "\(templates)"
            ] + (
                self.push ? ["--push"] : []
            ),
            in: clone
        )
        try process()
        return true
    }
}
extension Rarestcheck.Sync {
    private func table(
        repo: GitHub.Repo,
        refs: consuming Set<String>,
        labels: [(Substring, Substring?)]
    ) async throws -> String {
        var rows: [(id: String, display: Substring)] = []
        for (badge, display): (Substring, Substring?) in labels {
            guard
            let ref: String = refs.remove(String.init(badge)) else {
                continue
            }
            guard
            let display: Substring else {
                continue
            }
            rows.append((ref, display))
        }
        for ref: String in refs.sorted() {
            rows.append((ref, "????"))
        }

        var type: String = "Platform"
        for (ref, _): (String, _) in rows where (ref.prefix { $0 != "/" }) == "Audit" {
            type = "Policy"
            break
        }

        var markdown: String = """
        | \(type) | Status |
        | \(String.init(repeating: "-", count: type.count)) | ------ |
        """

        for (ref, display): (String, Substring) in rows {
            let workflow: Substring = ref.prefix { $0 != "/" }
            let image: String = try self.image(repo: repo, ref: ref)
            let yml: String = """
            https://github.com/\(repo.owner.login)/\(repo.name)/\
            actions/workflows/\(workflow).yml
            """
            markdown.append("\n")
            markdown += "| \(display) | [![Status](\(image))](\(yml)) |"
        }

        return markdown
    }

    private func image(repo: GitHub.Repo, ref: String) throws -> String {
        repo.visibility == .public ? """
        https://raw.githubusercontent.com/\(repo.owner.login)/\(repo.name)/refs/\
        badges/ci/\(ref)/status.svg
        """ : """
        https://github.com/\(repo.owner.login)/\(repo.name)/raw/\
        badges/ci/\(ref)/status.svg
        """
    }

    private func labelsInOrder(from file: FilePath) throws -> [(Substring, Substring?)] {
        var labels: [(Substring, Substring?)] = []
        try file.readLines {
            guard
            let colon: String.Index = $0.firstIndex(of: ":") else {
                return
            }
            let badge: Substring = $0[..<colon]
            if  let start: String.Index = $0[$0.index(after: colon)...].firstIndex(
                    where: { !$0.isWhitespace }
                ) {
                let value: Substring = $0[start...]
                labels.append((badge, value))
            } else {
                labels.append((badge, nil))
            }
        }
        return labels
    }
}
extension Rarestcheck.Sync {
    private func refs<T>(
        under refsNamespace: Rarestcheck.BadgingNamespace,
        clone: FilePath.Directory,
        into initial: consuming T,
        with combine: (inout T, Substring) throws -> ()
    ) async throws -> T {
        let git: (stdout: String, stderr: String) = try await Subprocess.capture {
            try SystemProcess.init(
                command: "git", "-C", "\(clone)", "ls-remote", "origin", "\(refsNamespace)/*",
                stdout: $1,
                stderr: $2
            )
        }

        let refs: [Substring] = git.stdout.split(whereSeparator: \.isNewline)
        return try refs.reduce(into: initial) {
            guard
            let gap: String.Index = $1.firstIndex(where: \.isWhitespace),
            let ref: String.Index = $1[gap...].firstIndex(
                where: { !$0.isWhitespace }
            ) else {
                return
            }

            try combine(&$0, $1[ref...])
        }
    }

    private func refs(
        repo: GitHub.Repo,
        clone: FilePath.Directory
    ) async throws -> Set<String> {
        let refsNamespace: Rarestcheck.BadgingNamespace

        if case .public = repo.visibility {
            refsNamespace = .ghost
        } else {
            refsNamespace = .compatibility
        }

        let prefix: String = "\(refsNamespace)/"
        let skip: Int = prefix.count
        return try await self.refs(
            under: refsNamespace,
            clone: clone,
            into: []
        ) {
            if  $1.starts(with: prefix) {
                // let’s not hold onto a small slice of a large buffer
                $0.insert(String.init($1.dropFirst(skip)))
            }
        }
    }

    private func vacuumBadges(
        repo: GitHub.Repo,
        clone: FilePath.Directory
    ) async throws {
        // We want to target the INVERSE of the correct namespace
        // to clean up stale or lingering badge refs.
        let complement: Rarestcheck.BadgingNamespace

        if case .public = repo.visibility {
            complement = .compatibility
        } else {
            complement = .ghost
        }

        let delete: [String] = try await self.refs(
            under: complement,
            clone: clone,
            into: []
        ) {
            print("detected stale ref \(repo.name):\($1)...")
            $0.append(":\($1)")
        }

        if  self.push, !delete.isEmpty {
            try SystemProcess.init(
                command: "git",
                arguments: ["push", "origin"] + delete,
                in: clone
            )()
        }
    }
}
