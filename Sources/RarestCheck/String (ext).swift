extension String {
    var lines: [Substring] {
        self.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
    }
}
