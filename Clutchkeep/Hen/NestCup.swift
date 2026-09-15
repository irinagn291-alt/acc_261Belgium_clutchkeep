import SwiftUI

/// Role: Hen. The one custom-drawn surface: a nest cup on the roost rail. Hairline glass tiles live here only.
struct NestCup: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let left = rect.minX + width * 0.14
        let right = rect.maxX - width * 0.14
        let rim = rect.minY + height * 0.34
        let lip = rect.minY + height * 0.18
        let floor = rect.maxY - height * 0.14
        path.move(to: CGPoint(x: left, y: rim))
        path.addQuadCurve(
            to: CGPoint(x: right, y: rim),
            control: CGPoint(x: rect.midX, y: lip)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: floor),
            control: CGPoint(x: rect.maxX - width * 0.05, y: floor - height * 0.08)
        )
        path.addQuadCurve(
            to: CGPoint(x: left, y: rim),
            control: CGPoint(x: rect.minX + width * 0.05, y: floor - height * 0.08)
        )
        path.closeSubpath()
        return path
    }
}

/// Role: Hen. Quiet roost rail behind the nest cups. Confined to the Flock hero.
struct RoostRailStroke: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let y = rect.maxY - rect.height * 0.16
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.04, y: y))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.04, y: y))
        return path
    }
}
