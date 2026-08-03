import CoreGraphics

enum JSRSpace {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum JSRRadius {
    static let control: CGFloat = 10
    static let container: CGFloat = 16
    static let sheet: CGFloat = 24
    static let motif: CGFloat = 4
}

enum JSRStroke {
    static let hairline: CGFloat = 1
    static let emphasis: CGFloat = 1.5
}

enum JSRIconSize {
    static let sm: CGFloat = 16
    static let md: CGFloat = 22
    static let lg: CGFloat = 28
}

enum JSRControl {
    static let minHit: CGFloat = 44
    static let railHeight: CGFloat = 56
}

enum JSRCanvasMetrics {
    static let square: CGSize = .init(width: 1080, height: 1080)
    static let portrait: CGSize = .init(width: 1080, height: 1440)
    static let landscape: CGSize = .init(width: 1440, height: 1080)
}
