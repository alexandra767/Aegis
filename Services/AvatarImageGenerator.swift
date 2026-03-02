import UIKit

enum AvatarImageGenerator {

    private nonisolated(unsafe) static let imageCache = NSCache<NSString, UIImage>()

    struct GradientSpec {
        let topColor: UIColor
        let bottomColor: UIColor
        let accentColor: UIColor
        let initial: String
    }

    static func gradientSpec(for avatar: AvatarConfig) -> GradientSpec {
        switch avatar.id {
        case "male1":   // Atlas — cyan→deep blue
            return GradientSpec(
                topColor: UIColor(red: 0, green: 0.95, blue: 1, alpha: 1),
                bottomColor: UIColor(red: 0, green: 0.25, blue: 0.7, alpha: 1),
                accentColor: UIColor(red: 0.4, green: 1, blue: 1, alpha: 0.6),
                initial: "A"
            )
        case "male2":   // Orion — purple→deep indigo
            return GradientSpec(
                topColor: UIColor(red: 0.65, green: 0.3, blue: 1, alpha: 1),
                bottomColor: UIColor(red: 0.2, green: 0.05, blue: 0.5, alpha: 1),
                accentColor: UIColor(red: 0.8, green: 0.5, blue: 1, alpha: 0.6),
                initial: "O"
            )
        case "male3":   // Nova — teal→emerald
            return GradientSpec(
                topColor: UIColor(red: 0, green: 0.9, blue: 0.75, alpha: 1),
                bottomColor: UIColor(red: 0, green: 0.4, blue: 0.35, alpha: 1),
                accentColor: UIColor(red: 0.3, green: 1, blue: 0.85, alpha: 0.6),
                initial: "N"
            )
        case "female1": // Aria — pink→deep rose
            return GradientSpec(
                topColor: UIColor(red: 1, green: 0.45, blue: 0.65, alpha: 1),
                bottomColor: UIColor(red: 0.6, green: 0.1, blue: 0.3, alpha: 1),
                accentColor: UIColor(red: 1, green: 0.6, blue: 0.8, alpha: 0.6),
                initial: "A"
            )
        case "female2": // Luna — lavender→deep violet
            return GradientSpec(
                topColor: UIColor(red: 0.75, green: 0.55, blue: 1, alpha: 1),
                bottomColor: UIColor(red: 0.3, green: 0.1, blue: 0.6, alpha: 1),
                accentColor: UIColor(red: 0.85, green: 0.7, blue: 1, alpha: 0.6),
                initial: "L"
            )
        case "female3": // Sage — amber→deep orange
            return GradientSpec(
                topColor: UIColor(red: 1, green: 0.65, blue: 0.1, alpha: 1),
                bottomColor: UIColor(red: 0.7, green: 0.3, blue: 0, alpha: 1),
                accentColor: UIColor(red: 1, green: 0.8, blue: 0.4, alpha: 0.6),
                initial: "S"
            )
        default:
            return GradientSpec(
                topColor: UIColor(red: 0, green: 0.95, blue: 1, alpha: 1),
                bottomColor: UIColor(red: 0, green: 0.25, blue: 0.7, alpha: 1),
                accentColor: UIColor(red: 0.4, green: 1, blue: 1, alpha: 0.6),
                initial: String(avatar.name.prefix(1))
            )
        }
    }

    static func generatePlaceholder(for avatar: AvatarConfig, size: CGFloat) -> UIImage {
        let renderSize = max(size, 100) // Minimum render resolution for quality
        let cacheKey = NSString(string: "\(avatar.id)_\(Int(renderSize))")
        if let cached = imageCache.object(forKey: cacheKey) {
            return cached
        }

        let spec = gradientSpec(for: avatar)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: renderSize, height: renderSize))

        let image = renderer.image { context in
            let rect = CGRect(origin: .zero, size: CGSize(width: renderSize, height: renderSize))
            let cgContext = context.cgContext
            let center = CGPoint(x: renderSize / 2, y: renderSize / 2)

            // Circular clip
            let circlePath = UIBezierPath(ovalIn: rect)
            circlePath.addClip()

            // Draw radial gradient background
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colors = [
                spec.topColor.cgColor,
                spec.bottomColor.cgColor
            ] as CFArray

            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
                cgContext.drawRadialGradient(
                    gradient,
                    startCenter: CGPoint(x: renderSize * 0.4, y: renderSize * 0.3),
                    startRadius: 0,
                    endCenter: center,
                    endRadius: renderSize * 0.7,
                    options: [.drawsAfterEndLocation]
                )
            }

            // Draw subtle inner glow
            let glowColors = [
                spec.accentColor.cgColor,
                spec.accentColor.withAlphaComponent(0).cgColor
            ] as CFArray

            if let glowGradient = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0]) {
                cgContext.drawRadialGradient(
                    glowGradient,
                    startCenter: CGPoint(x: renderSize * 0.35, y: renderSize * 0.25),
                    startRadius: 0,
                    endCenter: CGPoint(x: renderSize * 0.35, y: renderSize * 0.25),
                    endRadius: renderSize * 0.45,
                    options: []
                )
            }

            // Draw head silhouette (subtle darker shape)
            drawSilhouette(in: cgContext, size: renderSize, avatar: avatar)

            // Draw initial letter
            let fontSize = renderSize * 0.38
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let shadow = NSShadow()
            shadow.shadowColor = UIColor.black.withAlphaComponent(0.4)
            shadow.shadowBlurRadius = renderSize * 0.04
            shadow.shadowOffset = CGSize(width: 0, height: renderSize * 0.02)

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .heavy),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle,
                .shadow: shadow
            ]
            let text = spec.initial as NSString
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (renderSize - textSize.width) / 2,
                y: (renderSize - textSize.height) / 2 - renderSize * 0.02,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attributes)
        }

        imageCache.setObject(image, forKey: cacheKey)
        return image
    }

    // MARK: - Silhouette

    private static func drawSilhouette(in context: CGContext, size: CGFloat, avatar: AvatarConfig) {
        context.saveGState()
        context.setBlendMode(.softLight)

        let silhouetteColor = UIColor.white.withAlphaComponent(0.08)
        context.setFillColor(silhouetteColor.cgColor)

        let cx = size / 2
        // Head circle (upper portion)
        let headRadius = size * 0.18
        let headCenter = CGPoint(x: cx, y: size * 0.32)
        context.addEllipse(in: CGRect(
            x: headCenter.x - headRadius,
            y: headCenter.y - headRadius,
            width: headRadius * 2,
            height: headRadius * 2
        ))
        context.fillPath()

        // Shoulders (lower arc)
        let shoulderPath = UIBezierPath()
        shoulderPath.move(to: CGPoint(x: cx - size * 0.35, y: size))
        shoulderPath.addCurve(
            to: CGPoint(x: cx + size * 0.35, y: size),
            controlPoint1: CGPoint(x: cx - size * 0.28, y: size * 0.6),
            controlPoint2: CGPoint(x: cx + size * 0.28, y: size * 0.6)
        )
        shoulderPath.close()
        context.addPath(shoulderPath.cgPath)
        context.fillPath()

        context.restoreGState()
    }
}
