//
//  ProjectsGridView.swift
//  PKEditor
//
//  Created by Luca Rocchi on 05/07/25.
//


import SwiftUI

struct ProjectsGridView: View {
    // La griglia riceve i progetti da mostrare
    let projects: [ProjectItem]
    
    // Azione da eseguire al click, che riceve il progetto selezionato
    let onProjectSelected: (ProjectItem) -> Void
    let model = EditorModel.shared
    // Definiamo le colonne della griglia: layout adattivo che crea più colonne
    // possibili con una larghezza minima di 150 punti.
    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 150))
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    // Itera su ogni progetto per creare una cella
                    ForEach(projects) { project in
                        VStack(alignment: .leading) {
                            // AsyncImage carica l'immagine dall'URL in modo asincrono
                            AsyncImage(url: project.image) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit) // Riempie lo spazio
                            } placeholder: {
                                // Mostra un'icona di sistema mentre l'immagine carica
                                ZStack {
                                    Color(.secondarySystemBackground)
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(width:120,height: 120) // Altezza fissa per l'immagine
                            .clipShape(RoundedRectangle(cornerRadius: 12)) // Angoli arrotondati
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                            
                            // Nome del progetto
                            Text(project.name)
                                .font(.subheadline)
                                .frame(width:120,alignment:.center)
                                .lineLimit(2)
                            
                            Spacer()
                        }
                        .onTapGesture {
                            // Al tap, esegue l'azione definita dal genitore
                            onProjectSelected(project)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        model.showProjects = false
                            model.newProject()
                    }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        model.showProjects = false
                        model.showPhotoPicker = true
                    }) {
                        Image(systemName: "photo")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        model.showProjects = false
                        model.showCamera = true
                    }) {
                        Image(systemName: "camera")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        model.showProjects = false
                          model.showDocPicker = true
                    }) {
                        Image(systemName: "folder")
                    }
                }
                
               
                
            }
        }
    }
}
