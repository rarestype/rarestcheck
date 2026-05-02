extension Rarestcheck {
    enum InputPatternError: Error {
        case malformed(Substring)
        case redundant(Substring)
    }
}
