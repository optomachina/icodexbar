import AppKit
import XCTest

final class StatusIconRendererTests: XCTestCase {
    func testRendersAtCanvasSize() {
        let image = StatusIconRenderer.render(mode: .empty, accent: .systemPurple)

        XCTAssertEqual(image.size.width, 20)
        XCTAssertEqual(image.size.height, 18)
    }

    func testLiveZeroPercentRendersTrackOnly() throws {
        let image = StatusIconRenderer.render(
            mode: .live(primary: 0, secondary: 0),
            accent: .systemPurple
        )

        let pixels = try PixelMap(image: image)

        XCTAssertGreaterThan(pixels.maxAlpha, 0.1)
        XCTAssertLessThan(pixels.maxAlpha, 0.5)
    }

    func testLiveFullPercentFillsBar() throws {
        let image = StatusIconRenderer.render(
            mode: .live(primary: 100, secondary: nil),
            accent: .systemPurple
        )

        let pixels = try PixelMap(image: image)

        XCTAssertGreaterThan(pixels.maxAlpha(in: .rightHalf), 0.9)
    }

    func testEmptyMatchesLiveZero() throws {
        let empty = try PixelMap(image: StatusIconRenderer.render(mode: .empty, accent: .systemPurple))
        let liveZero = try PixelMap(image: StatusIconRenderer.render(
            mode: .live(primary: 0, secondary: 0),
            accent: .systemPurple
        ))

        XCTAssertEqual(empty.rgbaBytes, liveZero.rgbaBytes)
    }

    func testLoadingPhasePositionsSweep() throws {
        let leftImage = StatusIconRenderer.render(
            mode: .loading(phase: 0),
            accent: .systemPurple
        )
        let rightImage = StatusIconRenderer.render(
            mode: .loading(phase: 0.5),
            accent: .systemPurple
        )

        let leftPixels = try PixelMap(image: leftImage)
        let rightPixels = try PixelMap(image: rightImage)

        XCTAssertGreaterThan(leftPixels.opaquePixelCount(in: .leftHalf), leftPixels.opaquePixelCount(in: .rightHalf))
        XCTAssertGreaterThan(rightPixels.opaquePixelCount(in: .rightHalf), rightPixels.opaquePixelCount(in: .leftHalf))
    }

    func testStaleAppliesAlpha() throws {
        let live = try PixelMap(image: StatusIconRenderer.render(
            mode: .live(primary: 100, secondary: 100),
            accent: .systemPurple,
            isStale: false
        ))
        let stale = try PixelMap(image: StatusIconRenderer.render(
            mode: .live(primary: 100, secondary: 100),
            accent: .systemPurple,
            isStale: true
        ))

        XCTAssertLessThan(stale.maxAlpha, live.maxAlpha)
        XCTAssertGreaterThan(stale.maxAlpha, 0.35)
        XCTAssertLessThan(stale.maxAlpha, 0.6)
    }

    func testProviderAccentRendersDifferentFillColors() throws {
        let dark = try PixelMap(image: StatusIconRenderer.render(
            mode: .live(primary: 100, secondary: nil),
            accent: NSColor(red: 15 / 255, green: 15 / 255, blue: 15 / 255, alpha: 1)
        ))
        let purple = try PixelMap(image: StatusIconRenderer.render(
            mode: .live(primary: 100, secondary: nil),
            accent: NSColor(red: 139 / 255, green: 92 / 255, blue: 246 / 255, alpha: 1)
        ))

        XCTAssertLessThan(dark.averageOpaqueBlue, purple.averageOpaqueBlue)
        XCTAssertLessThan(dark.averageOpaqueRed, purple.averageOpaqueRed)
    }
}

private struct PixelMap {
    enum Region {
        case all
        case leftHalf
        case rightHalf
    }

    struct Pixel {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let alpha: CGFloat
    }

    let width: Int
    let height: Int
    let pixels: [Pixel]
    let rgbaBytes: [UInt8]

    init(image: NSImage) throws {
        guard
            let tiffData = image.tiffRepresentation,
            let rep = NSBitmapImageRep(data: tiffData)
        else {
            throw PixelError.missingBitmap
        }

        width = rep.pixelsWide
        height = rep.pixelsHigh

        var collected: [Pixel] = []
        var bytes: [UInt8] = []
        collected.reserveCapacity(width * height)
        bytes.reserveCapacity(width * height * 4)

        for y in 0..<height {
            for x in 0..<width {
                guard let color = rep.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else {
                    throw PixelError.missingColor
                }

                let pixel = Pixel(
                    red: color.redComponent,
                    green: color.greenComponent,
                    blue: color.blueComponent,
                    alpha: color.alphaComponent
                )
                collected.append(pixel)
                bytes.append(UInt8((pixel.red * 255).rounded()))
                bytes.append(UInt8((pixel.green * 255).rounded()))
                bytes.append(UInt8((pixel.blue * 255).rounded()))
                bytes.append(UInt8((pixel.alpha * 255).rounded()))
            }
        }

        pixels = collected
        rgbaBytes = bytes
    }

    var maxAlpha: CGFloat {
        maxAlpha(in: .all)
    }

    var averageOpaqueRed: CGFloat {
        averageOpaque(\.red)
    }

    var averageOpaqueBlue: CGFloat {
        averageOpaque(\.blue)
    }

    func maxAlpha(in region: Region) -> CGFloat {
        matching(region).map(\.alpha).max() ?? 0
    }

    func opaquePixelCount(in region: Region) -> Int {
        matching(region).filter { $0.alpha > 0.8 }.count
    }

    private func matching(_ region: Region) -> [Pixel] {
        pixels.enumerated().compactMap { index, pixel in
            let x = index % width
            switch region {
            case .all:
                return pixel
            case .leftHalf:
                return x < width / 2 ? pixel : nil
            case .rightHalf:
                return x >= width / 2 ? pixel : nil
            }
        }
    }

    private func averageOpaque(_ keyPath: KeyPath<Pixel, CGFloat>) -> CGFloat {
        let opaque = pixels.filter { $0.alpha > 0.8 }
        guard !opaque.isEmpty else { return 0 }
        let total = opaque.reduce(CGFloat(0)) { $0 + $1[keyPath: keyPath] }
        return total / CGFloat(opaque.count)
    }
}

private enum PixelError: Error {
    case missingBitmap
    case missingColor
}
