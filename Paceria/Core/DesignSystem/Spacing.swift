import CoreGraphics

enum Spacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum CornerRadius {
    static let card: CGFloat = 16
    static let button: CGFloat = 12
    static let chip: CGFloat = 8
}

enum Layout {
    /// Human Interface Guidelines の最小タップ領域。
    static let minimumTouchTarget: CGFloat = 44
}
