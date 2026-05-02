import ArgumentParser
import System_ArgumentParser
import SystemAsync
import SystemIO

extension Rarestcheck {
    struct SyncReadme {
        @Argument(
            help: "The path to the README file",
        ) var readme: FilePath

        @Option(
            name: [.customLong("version")],
            help: "The version identifier to inject"
        ) var version: String

        // this is currently unused, but we may start using it in the future
        @Option(
            name: [.customLong("repo"), .customShort("p")],
            help: "The repository identifier, owner/name"
        ) var repo: String?
    }
}
extension Rarestcheck.SyncReadme: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "sync-readme",
        )
    }

    func run() async throws {
        let readme: String = try self.readme.read()
        var lines: [Substring] = readme.lines
        let snippets: FilePath.Directory = self.root / ".github" / "snippets"
        if  try snippets.exists {
            try snippets.walk {
                let file: FilePath = $0 / $1

                guard case "md"? = $1.extension else {
                    return
                }

                var content: String = try file.read()

                content = content.replacing("__VERSION__", with: version)

                lines = Self.apply(to: lines, id: $1.stem) { $0 = content.lines }
            } directory: { (_, _) in
                .descend
            }
        }

        try self.readme.overwrite(lines: lines)
    }
}
extension Rarestcheck.SyncReadme {
    private var root: FilePath.Directory {
        self.readme.removingLastComponent().directory
    }
}
extension Rarestcheck.SyncReadme {
    static func apply(
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
