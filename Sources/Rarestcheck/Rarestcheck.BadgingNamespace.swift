extension Rarestcheck {
    enum BadgingNamespace {
        case ghost
        case compatibility
    }
}
extension Rarestcheck.BadgingNamespace: CustomStringConvertible {
    var description: String {
        switch self {
        case .ghost: "refs/badges/ci"
        case .compatibility: "refs/tags/badges/ci"
        }
    }
}
