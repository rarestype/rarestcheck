import ArgumentParser

@main struct Rarestcheck: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "rarestcheck",
            subcommands: self.subcommands,
        )
    }
}
extension Rarestcheck {
    private static var subcommands: [any AsyncParsableCommand.Type] {
        #if canImport(Cryptography)
        [SyncReadme.self, Exec.self, IAT.self]
        #else
        [SyncReadme.self]
        #endif
    }
}
