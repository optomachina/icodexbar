import AppKit

enum StatusIconRenderer {
    static let canvasSize = CGSize(width: 20, height: 18)

    enum Mode: Equatable {
        case live(primary: Double?, secondary: Double?)
        case loading(phase: CGFloat)
        case empty
    }

    static func render(mode: Mode, accent: NSColor, isStale: Bool = false) -> NSImage {
        let image = NSImage(size: canvasSize)
        image.isTemplate = false

        image.lockFocus()
        defer { image.unlockFocus() }

        guard let ctx = NSGraphicsContext.current?.cgContext else {
            return image
        }

        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)

        let topRect = CGRect(x: 2, y: 10, width: 16, height: 4)
        let bottomRect = CGRect(x: 2, y: 4, width: 16, height: 2)

        switch mode {
        case let .live(primary, secondary):
            drawBar(
                ctx: ctx,
                rect: topRect,
                cornerRadius: 1.5,
                trackAlpha: 0.22,
                fillFraction: clamped(primary),
                accent: accent
            )
            drawBar(
                ctx: ctx,
                rect: bottomRect,
                cornerRadius: 0.5,
                trackAlpha: 0.18,
                fillFraction: clamped(secondary),
                accent: accent
            )
        case .empty:
            drawBar(
                ctx: ctx,
                rect: topRect,
                cornerRadius: 1.5,
                trackAlpha: 0.22,
                fillFraction: 0,
                accent: accent
            )
            drawBar(
                ctx: ctx,
                rect: bottomRect,
                cornerRadius: 0.5,
                trackAlpha: 0.18,
                fillFraction: 0,
                accent: accent
            )
        case let .loading(phase):
            drawSweep(
                ctx: ctx,
                rect: topRect,
                cornerRadius: 1.5,
                trackAlpha: 0.22,
                phase: phase,
                segmentFraction: 0.25,
                accent: accent
            )
            drawSweep(
                ctx: ctx,
                rect: bottomRect,
                cornerRadius: 0.5,
                trackAlpha: 0.18,
                phase: (phase + 0.5).truncatingRemainder(dividingBy: 1),
                segmentFraction: 0.25,
                accent: accent
            )
        }

        if isStale {
            ctx.setBlendMode(.destinationOut)
            ctx.setFillColor(NSColor(white: 0, alpha: 0.55).cgColor)
            ctx.fill(CGRect(origin: .zero, size: canvasSize))
            ctx.setBlendMode(.normal)
        }

        return image
    }

    private static func clamped(_ percent: Double?) -> CGFloat {
        guard let percent else { return 0 }
        return CGFloat(max(0, min(1, percent / 100)))
    }

    private static func drawBar(
        ctx: CGContext,
        rect: CGRect,
        cornerRadius: CGFloat,
        trackAlpha: CGFloat,
        fillFraction: CGFloat,
        accent: NSColor
    ) {
        let path = CGPath(
            roundedRect: rect,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )

        ctx.addPath(path)
        ctx.setFillColor(accent.withAlphaComponent(trackAlpha).cgColor)
        ctx.fillPath()

        guard fillFraction > 0 else { return }

        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        ctx.setFillColor(accent.withAlphaComponent(1).cgColor)
        ctx.fill(CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width * fillFraction,
            height: rect.height
        ))
        ctx.restoreGState()
    }

    private static func drawSweep(
        ctx: CGContext,
        rect: CGRect,
        cornerRadius: CGFloat,
        trackAlpha: CGFloat,
        phase: CGFloat,
        segmentFraction: CGFloat,
        accent: NSColor
    ) {
        drawBar(
            ctx: ctx,
            rect: rect,
            cornerRadius: cornerRadius,
            trackAlpha: trackAlpha,
            fillFraction: 0,
            accent: accent
        )

        let normalized = phase.truncatingRemainder(dividingBy: 1)
        let triangle = normalized < 0.5 ? normalized * 2 : (1 - normalized) * 2
        let segmentWidth = max(1, rect.width * segmentFraction)
        let originX = rect.minX + (rect.width - segmentWidth) * triangle
        let path = CGPath(
            roundedRect: rect,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )

        ctx.saveGState()
        ctx.addPath(path)
        ctx.clip()
        ctx.setFillColor(accent.withAlphaComponent(1).cgColor)
        ctx.fill(CGRect(x: originX, y: rect.minY, width: segmentWidth, height: rect.height))
        ctx.restoreGState()
    }
}
