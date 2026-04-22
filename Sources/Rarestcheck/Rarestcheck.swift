import ArgumentParser

@main struct Rarestcheck: AsyncParsableCommand {
    static var configuration: CommandConfiguration {
        .init(
            commandName: "rarestcheck",
            subcommands: [SyncReadme.self],
        )
    }
}
