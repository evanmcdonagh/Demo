import SwiftUI

/// Draws the markings of a top-down Gaelic football pitch.
/// All coordinates are expressed as fractions of the bounding rect.
struct GaelicPitchShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height

        // Outer boundary
        p.addRect(rect)

        // Halfway line
        hLine(&p, y: 0.5, rect: rect)

        // Centre circle
        let cr = h * 0.075
        p.addEllipse(in: CGRect(x: w / 2 - cr, y: h / 2 - cr, width: cr * 2, height: cr * 2))

        // === Home end (top) ===
        // 21m line
        hLine(&p, y: 0.145, rect: rect)
        // 45m line
        hLine(&p, y: 0.31, rect: rect)
        // Small rectangle (goal area): 14m wide, ~4.5m deep
        let smallBoxW = w * 0.28, smallBoxH = h * 0.055
        let smallBoxX = (w - smallBoxW) / 2
        p.addRect(CGRect(x: smallBoxX + rect.minX, y: rect.minY, width: smallBoxW, height: smallBoxH))
        // Large rectangle: 45m wide, ~14m deep
        let largeBoxW = w * 0.62, largeBoxH = h * 0.10
        let largeBoxX = (w - largeBoxW) / 2
        p.addRect(CGRect(x: largeBoxX + rect.minX, y: rect.minY, width: largeBoxW, height: largeBoxH))
        // Goal posts (crossbar + 2 uprights)
        goalPosts(&p, atTopOf: true, rect: rect)

        // === Away end (bottom) — mirror ===
        hLine(&p, y: 0.855, rect: rect)
        hLine(&p, y: 0.69, rect: rect)
        p.addRect(CGRect(x: smallBoxX + rect.minX, y: rect.maxY - smallBoxH, width: smallBoxW, height: smallBoxH))
        p.addRect(CGRect(x: largeBoxX + rect.minX, y: rect.maxY - largeBoxH, width: largeBoxW, height: largeBoxH))
        goalPosts(&p, atTopOf: false, rect: rect)

        return p
    }

    private func hLine(_ p: inout Path, y: CGFloat, rect: CGRect) {
        let absY = rect.minY + rect.height * y
        p.move(to: CGPoint(x: rect.minX, y: absY))
        p.addLine(to: CGPoint(x: rect.maxX, y: absY))
    }

    private func goalPosts(_ p: inout Path, atTopOf: Bool, rect: CGRect) {
        let postInset = rect.width * 0.365
        let crossbarY: CGFloat = atTopOf ? rect.minY : rect.maxY
        let upright: CGFloat = rect.height * 0.045
        let postHeight: CGFloat = atTopOf ? -upright : upright

        // Left post
        p.move(to: CGPoint(x: rect.minX + postInset, y: crossbarY))
        p.addLine(to: CGPoint(x: rect.minX + postInset, y: crossbarY + postHeight))
        // Right post
        p.move(to: CGPoint(x: rect.maxX - postInset, y: crossbarY))
        p.addLine(to: CGPoint(x: rect.maxX - postInset, y: crossbarY + postHeight))
        // Crossbar
        p.move(to: CGPoint(x: rect.minX + postInset, y: crossbarY))
        p.addLine(to: CGPoint(x: rect.maxX - postInset, y: crossbarY))
    }
}
