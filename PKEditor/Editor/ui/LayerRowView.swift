//
//  LayerRowView.swift
//  PKEditor
//
//  Created by Luca Rocchi on 12/06/25.
//


import SwiftUI
import PencilKit

struct LayerRowView: View {
    @ObservedObject var layer: LayerModel
    @Binding var activeCanvas: Int // <-- 1. Accetta il binding

    var body: some View {
        HStack(spacing: 15) {
            if let layer = layer as? LayerCanvasModel{
                LayerThumbnailView(drawing: layer.drawing, size: CGSize(width: 60, height: 60))
                    .frame(width: 60, height: 60)
                    .background(Color(uiColor: .systemGray6))
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(uiColor: .systemGray3), lineWidth: 1)
                    )
            }
            if let layer = layer as? LayerImageModel,let image = layer.image{
                Image(uiImage:image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .background(Color(uiColor: .systemGray6))
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(uiColor: .systemGray3), lineWidth: 1)
                    )
            }
            VStack{
                Text(layer.name)
                Text(layer.type.rawValue).font(.subheadline).foregroundStyle(.secondary).bold()
            }

            Spacer()

            // 3. Checkbox/Pulsante per la visibilità
            Button(action: toggleVisibility) {
                // Usiamo un'icona a forma di occhio, più comune per la visibilità
                Image(systemName: layer.visible  ? "eye.fill" : "eye.slash.fill")
                    //.font(.title3)
                    .frame(width: 40)
            }
            .buttonStyle(.plain)
            
        }
        .padding(.vertical, 8)
        .listRowBackground(layer.currentCanvasId == activeCanvas ? Color.accentColor.opacity(0.3) : nil)
         .contentShape(Rectangle()) // Assicura che l'intera area della riga sia toccabile
         .onTapGesture {
             self.activeCanvas = layer.currentCanvasId
         }// Evita che l'intera riga diventi cliccabile
    }
    
    /// Cambia l'opacità per mostrare o nascondere il layer.
    private func toggleVisibility() {
        // Se l'opacità è 1.0 (visibile), la imposta a 0.0 (invisibile), e viceversa.
        layer.visible.toggle()
        //layer.opacity = (layer.opacity == 1.0) ? 0.0 : 1.0
    }
}
