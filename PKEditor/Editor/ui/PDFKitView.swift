//
//  PDFKitView.swift
//  Flowenti
//
//  Created by Luca Rocchi on 25/04/25.
//


import SwiftUI
import PDFKit

struct PDFKitView: UIViewRepresentable {

    var pdfDocument: PDFDocument = PDFDocument()

    init(showing pdfDoc: PDFDocument) {
        self.pdfDocument = pdfDoc
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = pdfDocument
    }
}

struct PDFUIView: View {

    var pdfDoc: PDFDocument = PDFDocument()

    /*
    init() {
        //for the sake of example, we're going to assume
        //you have a file Lipsum.pdf in your bundle
        let url = Bundle.main.url(forResource: "Lipsum", withExtension: "pdf")!
        pdfDoc = PDFDocument(url: url)!
    }
    */

    init(data:Data) {
        if let pdfDoc = PDFDocument(data: data){
            self.pdfDoc = pdfDoc
        }
    }
    
    init(text:String) {
        let pdfDoc = PDFDocument()
        self.pdfDoc = pdfDoc
        //self.pdfDoc.text(text)
    }
   
    
    var body: some View {
        PDFKitView(showing: pdfDoc)
    }
}

func drawPDFfromURL(url: URL) -> UIImage? {
    guard let document = CGPDFDocument(url as CFURL) else { return nil }
    guard let page = document.page(at: 1) else { return nil }

    let pageRect = page.getBoxRect(.mediaBox)
    let renderer = UIGraphicsImageRenderer(size: pageRect.size)
    let img = renderer.image { ctx in
        UIColor.white.set()
        ctx.fill(pageRect)

        ctx.cgContext.translateBy(x: 0.0, y: pageRect.size.height)
        ctx.cgContext.scaleBy(x: 1.0, y: -1.0)

        ctx.cgContext.drawPDFPage(page)
    }

    return img
}
