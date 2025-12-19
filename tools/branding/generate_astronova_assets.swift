import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct AstronovaMarkStyle {
    var backgroundTopLeft: CGColor
    var backgroundBottomRight: CGColor
    var glowColor: CGColor
    var orbitGradientStart: CGColor
    var orbitGradientEnd: CGColor
    var starGradientTop: CGColor
    var starGradientBottom: CGColor
    var planetColor: CGColor

    static let `default` = AstronovaMarkStyle(
        backgroundTopLeft: CGColor(srgbRed: 0.03, green: 0.03, blue: 0.09, alpha: 1),
        backgroundBottomRight: CGColor(srgbRed: 0.05, green: 0.22, blue: 0.46, alpha: 1),
        glowColor: CGColor(srgbRed: 0.46, green: 0.40, blue: 0.98, alpha: 0.50),
        orbitGradientStart: CGColor(srgbRed: 0.80, green: 0.95, blue: 1.00, alpha: 0.85),
        orbitGradientEnd: CGColor(srgbRed: 0.45, green: 0.85, blue: 1.00, alpha: 0.60),
        starGradientTop: CGColor(srgbRed: 1.00, green: 1.00, blue: 1.00, alpha: 1.00),
        starGradientBottom: CGColor(srgbRed: 0.62, green: 0.92, blue: 1.00, alpha: 1.00),
        planetColor: CGColor(srgbRed: 0.98, green: 0.75, blue: 0.15, alpha: 1.00)
    )
}

struct AstronovaMarkGeometry {
    var orbitRadiusRatio: CGFloat = 0.335
    var orbitStrokeRatio: CGFloat = 0.070
    var orbitStartAngleDegrees: CGFloat = 160
    var orbitEndAngleDegrees: CGFloat = 470

    var planetAngleDegrees: CGFloat = 22
    var planetRadiusRatio: CGFloat = 0.040

    var starPoints: Int = 4
    var starOuterRadiusRatio: CGFloat = 0.200
    var starInnerRadiusRatio: CGFloat = 0.075
    var starRotationDegrees: CGFloat = -90
}

enum BrandingError: Error {
    case contextCreationFailed
    case imageCreationFailed
    case imageDestinationCreationFailed
    case imageFinalizeFailed
}

@main
enum GenerateAstronovaAssets {
    static func main() throws {
        let args = CommandLine.arguments.dropFirst()
        let outputDir = URL(fileURLWithPath: args.first ?? "tools/branding/output", isDirectory: true)
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        let style = AstronovaMarkStyle.default
        let geometry = AstronovaMarkGeometry()

        let icon1024 = try renderMark(size: 1024, style: style, geometry: geometry)
        try writePNG(icon1024, to: outputDir.appendingPathComponent("astronova-icon-1024.png"))

        let logo1024 = try renderMark(size: 1024, style: style, geometry: geometry, includeBackground: false)
        try writePNG(logo1024, to: outputDir.appendingPathComponent("astronova-mark-1024.png"))

        print("Generated:")
        print("- \(outputDir.appendingPathComponent("astronova-icon-1024.png").path)")
        print("- \(outputDir.appendingPathComponent("astronova-mark-1024.png").path)")
    }

    private static func renderMark(
        size: Int,
        style: AstronovaMarkStyle,
        geometry: AstronovaMarkGeometry,
        includeBackground: Bool = true
    ) throws -> CGImage {
        let width = size
        let height = size
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw BrandingError.contextCreationFailed
        }

        let canvas = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
        let center = CGPoint(x: canvas.midX, y: canvas.midY)

        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        context.interpolationQuality = .high

        if includeBackground {
            drawBackground(context: context, canvas: canvas, style: style, colorSpace: colorSpace)
        } else {
            context.clear(canvas)
        }

        drawOrbit(context: context, canvas: canvas, center: center, style: style, geometry: geometry, colorSpace: colorSpace)
        drawPlanet(context: context, canvas: canvas, center: center, style: style, geometry: geometry, colorSpace: colorSpace)
        drawStar(context: context, canvas: canvas, center: center, style: style, geometry: geometry, colorSpace: colorSpace)

        guard let image = context.makeImage() else {
            throw BrandingError.imageCreationFailed
        }

        return image
    }

    private static func drawBackground(context: CGContext, canvas: CGRect, style: AstronovaMarkStyle, colorSpace: CGColorSpace) {
        context.saveGState()
        defer { context.restoreGState() }

        context.setFillColor(style.backgroundTopLeft)
        context.fill(canvas)

        if let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: [style.backgroundTopLeft, style.backgroundBottomRight] as CFArray,
            locations: [0.0, 1.0]
        ) {
            context.drawLinearGradient(
                gradient,
                start: CGPoint(x: canvas.minX, y: canvas.maxY),
                end: CGPoint(x: canvas.maxX, y: canvas.minY),
                options: []
            )
        }

        let glowCenter = CGPoint(x: canvas.midX * 0.92, y: canvas.midY * 1.06)
        if let glow = CGGradient(
            colorsSpace: colorSpace,
            colors: [style.glowColor, CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 0)] as CFArray,
            locations: [0.0, 1.0]
        ) {
            context.drawRadialGradient(
                glow,
                startCenter: glowCenter,
                startRadius: 0,
                endCenter: glowCenter,
                endRadius: canvas.width * 0.62,
                options: [.drawsAfterEndLocation]
            )
        }
    }

    private static func drawOrbit(
        context: CGContext,
        canvas: CGRect,
        center: CGPoint,
        style: AstronovaMarkStyle,
        geometry: AstronovaMarkGeometry,
        colorSpace: CGColorSpace
    ) {
        context.saveGState()
        defer { context.restoreGState() }

        let orbitRadius = canvas.width * geometry.orbitRadiusRatio
        let strokeWidth = canvas.width * geometry.orbitStrokeRatio

        let start = geometry.orbitStartAngleDegrees * (.pi / 180)
        let end = geometry.orbitEndAngleDegrees * (.pi / 180)

        context.setLineWidth(strokeWidth)
        context.setLineCap(.round)
        context.addArc(center: center, radius: orbitRadius, startAngle: start, endAngle: end, clockwise: false)
        context.replacePathWithStrokedPath()
        context.clip()

        if let orbitGradient = CGGradient(
            colorsSpace: colorSpace,
            colors: [style.orbitGradientStart, style.orbitGradientEnd] as CFArray,
            locations: [0.0, 1.0]
        ) {
            context.drawLinearGradient(
                orbitGradient,
                start: CGPoint(x: canvas.midX, y: canvas.maxY),
                end: CGPoint(x: canvas.midX, y: canvas.minY),
                options: []
            )
        }
    }

    private static func drawPlanet(
        context: CGContext,
        canvas: CGRect,
        center: CGPoint,
        style: AstronovaMarkStyle,
        geometry: AstronovaMarkGeometry,
        colorSpace: CGColorSpace
    ) {
        context.saveGState()
        defer { context.restoreGState() }

        let orbitRadius = canvas.width * geometry.orbitRadiusRatio
        let angle = geometry.planetAngleDegrees * (.pi / 180)
        let position = CGPoint(
            x: center.x + orbitRadius * cos(angle),
            y: center.y + orbitRadius * sin(angle)
        )
        let planetRadius = canvas.width * geometry.planetRadiusRatio
        let planetRect = CGRect(
            x: position.x - planetRadius,
            y: position.y - planetRadius,
            width: planetRadius * 2,
            height: planetRadius * 2
        )

        context.setShadow(offset: CGSize(width: 0, height: -planetRadius * 0.35), blur: planetRadius * 0.9, color: style.planetColor.copy(alpha: 0.55))
        context.setFillColor(style.planetColor)
        context.fillEllipse(in: planetRect)

        context.setShadow(offset: .zero, blur: 0, color: nil)
        if let highlight = CGGradient(
            colorsSpace: colorSpace,
            colors: [CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.65), CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0)] as CFArray,
            locations: [0.0, 1.0]
        ) {
            let highlightCenter = CGPoint(x: planetRect.midX - planetRadius * 0.35, y: planetRect.midY + planetRadius * 0.35)
            context.saveGState()
            context.addEllipse(in: planetRect.insetBy(dx: planetRadius * 0.18, dy: planetRadius * 0.18))
            context.clip()
            context.drawRadialGradient(
                highlight,
                startCenter: highlightCenter,
                startRadius: 0,
                endCenter: highlightCenter,
                endRadius: planetRadius * 1.4,
                options: [.drawsAfterEndLocation]
            )
            context.restoreGState()
        }
    }

    private static func drawStar(
        context: CGContext,
        canvas: CGRect,
        center: CGPoint,
        style: AstronovaMarkStyle,
        geometry: AstronovaMarkGeometry,
        colorSpace: CGColorSpace
    ) {
        context.saveGState()
        defer { context.restoreGState() }

        let outerRadius = canvas.width * geometry.starOuterRadiusRatio
        let innerRadius = canvas.width * geometry.starInnerRadiusRatio
        let rotation = geometry.starRotationDegrees * (.pi / 180)

        let starPath = makeStarPath(center: center, outerRadius: outerRadius, innerRadius: innerRadius, points: geometry.starPoints, rotation: rotation)

        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -outerRadius * 0.06), blur: outerRadius * 0.22, color: CGColor(srgbRed: 0.36, green: 0.86, blue: 1.00, alpha: 0.40))
        context.addPath(starPath)
        context.clip()

        if let starGradient = CGGradient(
            colorsSpace: colorSpace,
            colors: [style.starGradientTop, style.starGradientBottom] as CFArray,
            locations: [0.0, 1.0]
        ) {
            context.drawLinearGradient(
                starGradient,
                start: CGPoint(x: center.x, y: center.y + outerRadius),
                end: CGPoint(x: center.x, y: center.y - outerRadius),
                options: []
            )
        } else {
            context.setFillColor(style.starGradientTop)
            context.addPath(starPath)
            context.fillPath()
        }
        context.restoreGState()
    }

    private static func makeStarPath(
        center: CGPoint,
        outerRadius: CGFloat,
        innerRadius: CGFloat,
        points: Int,
        rotation: CGFloat
    ) -> CGPath {
        let path = CGMutablePath()
        var angle = rotation
        let increment = .pi / CGFloat(points)
        var isOuter = true

        for index in 0..<(points * 2) {
            let radius = isOuter ? outerRadius : innerRadius
            let x = center.x + radius * cos(angle)
            let y = center.y + radius * sin(angle)
            let point = CGPoint(x: x, y: y)

            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }

            isOuter.toggle()
            angle += increment
        }

        path.closeSubpath()
        return path
    }

    private static func writePNG(_ image: CGImage, to url: URL) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw BrandingError.imageDestinationCreationFailed
        }

        CGImageDestinationAddImage(destination, image, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw BrandingError.imageFinalizeFailed
        }
    }
}
