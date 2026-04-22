import ArgumentParser

@main struct RarestCheck: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "rarestcheck",
            subcommands: [SyncReadme.self],
        )
    }
}
