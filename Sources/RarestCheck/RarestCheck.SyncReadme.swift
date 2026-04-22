import ArgumentParser
import System_ArgumentParser
import SystemAsync
import SystemIO

extension RarestCheck {
    struct SyncReadme {
        @Argument(
            help: "The path to the README file",
        ) var readme: FilePath

        @Option(
            name: [.customLong("labels")],
            help: "The path to the status labels configuration",
        ) var labels: FilePath

        @Option(
            name: [.customLong("repo"), .customShort("p")],
            help: "The path to the project directory (containing Package.swift)"
        ) var repo: String

        @Flag(
            name: [.customLong("repo-is-private")],
            help: "Whether the repository is private"
        ) var repoIsPrivate: Bool = false
    }
}
extension RarestCheck.SyncReadme: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "sync-readme",
        )
    }

    func run() async throws {
        let readme: String = try self.readme.read()
        let table: String = try await self.table
        let lines: [Substring] = Self.apply(to: readme.lines, id: "STATUS TABLE") {
            $0 = table.lines
        }
        let content: [UInt8] = [_].init(lines.lazy.map(\.utf8).joined(separator: [0xa]))
        try self.readme.overwrite(with: content[...])
    }
}
extension RarestCheck.SyncReadme {
    private static func apply(
        to lines: consuming [Substring],
        id: String,
        rewrite: (inout [Substring]) -> (),
    ) -> [Substring] {
        let fence: (above: String, below: String) = (
            "<!-- DO NOT EDIT BELOW! AUTOSYNC CONTENT [\(id)] -->",
            "<!-- DO NOT EDIT ABOVE! AUTOSYNC CONTENT [\(id)] -->",
        )
        var filtered: [Substring] = []
        ;   filtered.reserveCapacity(lines.count)
        var selected: [Substring]? = nil
        for line: Substring in lines {
            if  line == fence.above {
                selected = []
            } else if
                line == fence.below {
                if  var region: [Substring] = consume selected {
                    rewrite(&region)

                    filtered.append(fence.above[...])
                    filtered += region
                    filtered.append(fence.below[...])
                }
                selected = nil
            } else if
                var region: [Substring] = consume selected {
                region.append(line)
                selected = region
            } else {
                filtered.append(line)
                selected = nil
            }
        }
        if var incomplete: [Substring] = consume selected {
            rewrite(&incomplete)

            filtered.append(fence.above[...])
            filtered += incomplete
        }
        return filtered
    }
}
extension RarestCheck.SyncReadme {
    private var table: String {
        get async throws {
            var refs: Set<String> = try await self.refs
            var rows: [(String, display: Substring)] = []
            for (badge, display): (Substring, Substring) in try self.labelsInOrder() {
                guard
                let ref: String = refs.remove(String.init(badge)) else {
                    continue
                }
                rows.append((ref, display))
            }
            for ref: String in refs.sorted() {
                rows.append((ref, "????"))
            }

            var markdown: String = """
            | Platform | Status |
            | -------- | ------ |
            """

            for (ref, display): (String, Substring) in rows {
                let workflow: Substring = ref.prefix { $0 != "/" }
                let image: String = self.image(ref: ref)
                let yml: String = """
                https://github.com/\(self.repo)/actions/workflows/\(workflow).yml
                """
                markdown.append("\n")
                markdown += "| \(display) | [![Status](\(image))](\(yml)) |"
            }

            return markdown
        }
    }

    private var refsNamespace: String {
        self.repoIsPrivate ? "refs/tags/badges/ci/" : "refs/badges/ci/"
    }
    private var refs: Set<String> {
        get async throws {
            let url: String = "https://github.com/\(self.repo).git"
            let git: (stdout: String, stderr: String) = try await SystemProcess.capture {
                try SystemProcess.init(command: "git", "ls-remote", url, stdout: $1, stderr: $2)
            }

            let refsNamespace: String = self.refsNamespace
            let skip: Int = refsNamespace.count
            let refs: [Substring] = git.stdout.split(whereSeparator: \.isNewline)
            let keys: Set<String> = refs.reduce(into: []) {
                guard
                let gap: String.Index = $1.firstIndex(where: \.isWhitespace),
                let ref: String.Index = $1[gap...].firstIndex(where: \.isLetter) else {
                    return
                }

                let full: Substring = $1[ref...]

                if  full.starts(with: refsNamespace) {
                    // let’s not hold onto a small slice of a large buffer
                    $0.insert(String.init($1[ref...].dropFirst(skip)))
                }
            }

            return keys
        }
    }

    private func labelsInOrder() throws -> [(Substring, Substring)] {
        var labels: [(Substring, Substring)] = []
        try self.labels.readLines {
            let string: String = .init(decoding: $0, as: Unicode.UTF8.self)
            guard
            let colon: String.Index = string.firstIndex(of: ":") else {
                return
            }
            let badge: Substring = string[..<colon]
            if  let start: String.Index = string[string.index(after: colon)...].firstIndex(
                    where: { !$0.isWhitespace }
                ) {
                let value: Substring = string[start...]
                labels.append((badge, value))
            } else {
                labels.append((badge, ""))
            }
        }
        return labels
    }

    private func image(ref: String) -> String {
        self.repoIsPrivate ? """
        https://github.com/\(self.repo)/raw/badges/ci/\(ref)/status.svg
        """ : """
        https://raw.githubusercontent.com/\(self.repo)/refs/badges/ci/\(ref)/status.svg
        """
    }
}
