//
//  MenuImageFilter.swift
//  PKEditor
//
//  Created by Luca Rocchi on 14/08/25.
//

import SwiftUI

struct MenuProject: View {
    @ObservedObject var model = EditorModel.shared
 
    var body: some View {
        Menu() {
            //Text("Projects").italic()
            Button(action: {
               model.showProjects = true
            }) {
               Text("Open project")
            }
            
            Button(action: {
               model.saveProject()
            }) {
               Text("Save")
            }
            
            Button(action: {
               model.saveProjectAs = true
            }) {
               Text("Save as...")
            }
            
            Button(action: {
                model.exportToGallery()
            }) {
               Text("Save to gallery")
            }
            
            Button(action: {
                model.showRenameProject = true
            }) {
               Text("Rename...")
            }
            
            Button(action: {
                model.publish()
            }) {
               Text("Publish...")
            }
            
            Button("Delete...",role:.destructive) {
                model.showDeleteProject = true
            }
            
           
            
            
        } label: {
            Image(systemName: "fireworks")
        }
        
        
        
        /*
         let saveAction = UIAction(title: "Save", image: nil) { _ in
             EditorModel.shared.saveProject()
         }
         let saveAsAction = UIAction(title: "Save as...", image: nil) { _ in
             EditorModel.shared.saveProjectAs = true
         }
         
          let renameAction = UIAction(title: "Rename", image: nil) { _ in
              self.showRenameProject = true
          }
          let deleteAction = UIAction(
              title: "Delete",
              image: UIImage(systemName: "trash"),
              attributes: .destructive) { action in
                  self.showDeleteProject = true
          }
          let deleteMenu = UIMenu(
              options: .displayInline, // <-- Questa è la riga chiave
              children: [deleteAction]
          )

         let saveToGallery = UIAction(title: "Save to gallery", image: nil) { _ in
             self.exportToGallery()
         }
          
          
         let publishAction = UIAction(title: "Publish...", image: nil) { _ in
             self.publish()
         }
          
         */
        
    }
}

#Preview {
    MenuProject()
}
