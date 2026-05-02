import SystemIO

extension FilePath {
    func overwrite(lines: consuming [Substring]) throws {
        let content: [UInt8] = [_].init(lines.lazy.map(\.utf8).joined(separator: [0xa]))
        try self.overwrite(with: content[...])
    }
}
