//
//  PDFExport.swift
//  PrensaIA
//
//  Exportación a PDF y hoja de compartir del sistema.
//

import SwiftUI
import UIKit
import CoreText

// MARK: - Compartir archivos (hoja del sistema)

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

// MARK: - Generador de PDF (con paginación automática)

enum PDFMaker {
    static func make(title: String, dateText: String, body: String) -> URL? {
        let pageWidth: CGFloat = 612   // Carta 8.5"
        let pageHeight: CGFloat = 792  // 11"
        let margin: CGFloat = 54       // 0.75"
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let contentRect = CGRect(
            x: margin, y: margin,
            width: pageWidth - margin * 2,
            height: pageHeight - margin * 2
        )

        let full = NSMutableAttributedString()
        full.append(NSAttributedString(string: "PrensaIA\n", attributes: [
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: UIColor.systemIndigo
        ]))
        full.append(NSAttributedString(string: title + "\n", attributes: [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: UIColor.label
        ]))
        full.append(NSAttributedString(string: dateText + "\n\n", attributes: [
            .font: UIFont.systemFont(ofSize: 10.5),
            .foregroundColor: UIColor.secondaryLabel
        ]))
        let bodyStyle = NSMutableParagraphStyle()
        bodyStyle.lineSpacing = 4
        bodyStyle.paragraphSpacing = 9
        full.append(NSAttributedString(string: body, attributes: [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.label,
            .paragraphStyle: bodyStyle
        ]))

        var safe = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if safe.isEmpty { safe = "Transcripcion" }
        safe = safe.replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safe).pdf")

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        do {
            try renderer.writePDF(to: url) { ctx in
                let framesetter = CTFramesetterCreateWithAttributedString(full as CFAttributedString)
                var position = 0
                let total = full.length
                while position < total {
                    ctx.beginPage()
                    let cg = ctx.cgContext
                    cg.textMatrix = .identity
                    cg.translateBy(x: 0, y: pageHeight)
                    cg.scaleBy(x: 1, y: -1)
                    let framePath = CGPath(rect: contentRect, transform: nil)
                    let frame = CTFramesetterCreateFrame(
                        framesetter,
                        CFRangeMake(position, 0),
                        framePath, nil
                    )
                    CTFrameDraw(frame, cg)
                    let visible = CTFrameGetVisibleStringRange(frame)
                    if visible.length == 0 { break }
                    position += visible.length
                }
            }
            return url
        } catch {
            return nil
        }
    }
}
