//
//  LayersListView.swift
//  PKEditor
//
//  Created by Luca Rocchi on 12/06/25.
//


import SwiftUI
import PhotosUI

struct LayersListView: View {
    @ObservedObject var model: EditorModel = EditorModel.shared
    @Environment(\.dismiss) private var dismiss // Per chiudere lo sheet
    @Binding var activeCanvas: Int // <-- 1. Accetta il binding
    @State var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        // NavigationView è necessaria per avere una barra del titolo e i pulsanti
        NavigationView {
            List {
                // Itera sui layer per creare le righe
                ForEach(model.layers) { layer in
                    LayerRowView(layer: layer,activeCanvas: $activeCanvas)
                        .tag(layer.currentCanvasId)
                }
                .onMove(perform: moveLayer) // Abilita il drag-and-drop
                .onDelete(perform: deleteLayer) // <-- 1. AGGIUNGI QUESTO MODIFICATORE
                
            }
            .onAppear {
                //model.objectWillChange.send()
            }
            .photosPicker(
                       isPresented: $showPhotoPicker, // Usa la variabile che già hai
                       selection: $selectedPhotoItem,
                       matching: .images
                   )
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    model.selectedStroke = nil
                    
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        if let image = UIImage(data: data) {
                            model.addImageLayer(image:image)
                        }
                    }
                    
                }
            }
            .listStyle(.plain)
            .navigationTitle("Layers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                //ToolbarItem(placement: .navigationBarTrailing) {
                //    EditButton()
                //}
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        DispatchQueue.main.async {
                            model.selectedStroke = nil
                            model.addLayer()
                        }
                        
                        
                    }) {
                        Image(systemName: "pencil.tip.crop.circle.badge.plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                        DispatchQueue.main.async {
                            showPhotoPicker = true
                            //model.selectedStroke = nil
                            //model.addImageLayer()
                        }
                        
                      
                    }) {
                        Image(systemName: "photo.badge.plus")
                    }
                    
                }
                
            }
        }
    }
    
    /// Funzione chiamata quando un layer viene spostato nella lista.
    /// Aggiorna direttamente l'ordine nell'array del modello.
    private func moveLayer(from source: IndexSet, to destination: Int) {
        model.layers.move(fromOffsets: source, toOffset: destination)
        //model.setBackgroundColor()
        model.selectedStroke = nil
    }
    private func deleteLayer(at offsets: IndexSet) { 
        if model.layers.count > 1 {
            model.layers.remove(atOffsets: offsets)
            model.activeCanvasId = model.layers[0].currentCanvasId
            //model.setBackgroundColor()
            model.selectedStroke = nil
        }
    }
}
