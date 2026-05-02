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
        [SyncReadme.self, Sync.self, Audit.self]
        #else
        [SyncReadme.self]
        #endif
    }
}
