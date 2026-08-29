import Assert
import Bijection

enum Color: CaseIterable, Equatable {
    case red
    case green
    case blue

    @Bijection var name: String {
        switch self {
        case .red: "red"
        case .green: "green"
        case .blue: "blue"
        }
    }
}

#assert(Color.init("red") == .red, "color init failed")
