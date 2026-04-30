extension Rarestcheck.Exec {
    enum InputPatternError: Error {
        case malformed(Substring)
        case redundant(Substring)
    }
}
