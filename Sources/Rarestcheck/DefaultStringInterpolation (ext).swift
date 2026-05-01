extension DefaultStringInterpolation {
    mutating func appendInterpolation(accent string: some CustomStringConvertible) {
        self.appendInterpolation(string: string, color: (255, 110, 195))
    }
    mutating func appendInterpolation(fail string: some CustomStringConvertible) {
        self.appendInterpolation(string: string, color: (255, 110, 110))
    }

    mutating func appendInterpolation(bold string: some CustomStringConvertible) {
        self.appendInterpolation("\u{1B}[1m\(string)\u{1B}[0m")
    }

    mutating func appendInterpolation(
        string: some CustomStringConvertible,
        color: (r: UInt8, g: UInt8, b: UInt8),
    ) {
        self.appendInterpolation(
            "\u{1B}[38;2;\(color.r);\(color.g);\(color.b)m\u{1B}[1m\(string)\u{1B}[0m"
        )
    }
}
