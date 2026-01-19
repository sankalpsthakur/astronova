import AppKit
import CoreGraphics
import Foundation

func usage() -> Never {
    fputs("Usage: pdf_render <input.pdf> <output_dir> [scale]\n", stderr)
    exit(2)
}

let args = CommandLine.arguments
guard args.count >= 3 else { usage() }

let inputPath = args[1]
let outputDir = args[2]
let scale = (args.count >= 4 ? Double(args[3]) : nil) ?? 2.0
if scale <= 0 { usage() }

let inputURL = URL(fileURLWithPath: inputPath)
guard let doc = CGPDFDocument(inputURL as CFURL) else {
    fputs("Failed to open PDF: \(inputPath)\n", stderr)
    exit(1)
}

let fm = FileManager.default
do {
    try fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
} catch {
    fputs("Failed to create output dir: \(outputDir)\n", stderr)
    exit(1)
}

let pageCount = doc.numberOfPages
if pageCount == 0 {
    fputs("PDF has 0 pages: \(inputPath)\n", stderr)
    exit(1)
}

for pageNumber in 1...pageCount {
    guard let page = doc.page(at: pageNumber) else { continue }
    let bounds = page.getBoxRect(.mediaBox)

    let widthPx = Int((bounds.width * scale).rounded(.up))
    let heightPx = Int((bounds.height * scale).rounded(.up))

    guard widthPx > 0, heightPx > 0 else { continue }

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    guard let ctx = CGContext(
        data: nil,
        width: widthPx,
        height: heightPx,
        bitsPerComponent: 8,
        bytesPerRow: widthPx * 4,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    ) else {
        fputs("Failed to create CGContext for page \(pageNumber)\n", stderr)
        continue
    }

    ctx.setFillColor(NSColor.white.cgColor)
    ctx.fill(CGRect(x: 0, y: 0, width: widthPx, height: heightPx))

    ctx.saveGState()
    // PDF coordinate system: origin bottom-left. Bitmap: origin top-left.
    ctx.translateBy(x: 0, y: CGFloat(heightPx))
    ctx.scaleBy(x: scale, y: -scale)
    ctx.drawPDFPage(page)
    ctx.restoreGState()

    guard let cgImage = ctx.makeImage() else {
        fputs("Failed to render page \(pageNumber)\n", stderr)
        continue
    }

    let rep = NSBitmapImageRep(cgImage: cgImage)
    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        fputs("Failed to encode PNG for page \(pageNumber)\n", stderr)
        continue
    }

    let outURL = URL(fileURLWithPath: outputDir)
        .appendingPathComponent(String(format: "page_%03d.png", pageNumber))

    do {
        try pngData.write(to: outURL)
        print("Wrote \(outURL.path)")
    } catch {
        fputs("Failed to write \(outURL.path): \(error)\n", stderr)
    }
}

