//
//  EditorModel+Menu.swift
//  PKEditor
//
//  Created by Luca Rocchi on 22/06/25.
//

import Foundation
import Combine
import UIKit
@preconcurrency import PencilKit


extension EditorModel {
     func createPopupMenu(){
        // --- Sottomenu "File" ---
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
         
         
        // Creiamo il sottomenu "File" con le azioni definite sopra
        
         
         //let newAction = UIAction(title: "New", image: nil) { _ in
          //    EditorModel.shared.newProject()
          //}
          
          /*let loadAction = UIAction(title: "from project", image: nil) { _ in
              //EditorModel.shared.loadProject()
              self.showDocPicker = true
          }
          
          let openFromGallery = UIAction(title: "from gallery", image: nil) { _ in
              //EditorModel.shared.loadProject()
              self.showPhotoPicker = true
          }
          
          let openFromCamera = UIAction(title: "from camera", image: nil) { _ in
              //EditorModel.shared.loadProject()
              //self.showDocPicker = true
          }
           */
          //let openMenu = UIMenu(title: "Open...", children: //[loadAction,openFromGallery,openFromCamera])
        
        
         
         /*let recentActions = EditorModel.shared.recentProjects.map{ item in
             let recentAction = UIAction(title: item.name, image: nil) { _ in
                 EditorModel.shared.loadProject(item.name )
                
             }
             return recentAction
          }*/
          
          //let recentMenu = UIMenu(title: "Open recent", children: recentActions.reversed())
        
          
        
        /*let undoAction = UIAction(title: "Undo", image: nil) { _ in
            
            EditorModel.shared.undo()
            
        }
        let redoAction = UIAction(title: "Redo", image: nil) { _ in
            
            EditorModel.shared.redo()
            
        }*/
        
       
        /*
        let zoomToFitAction = UIAction(title: "Zoom to fit", image: nil) { _ in
            
            EditorModel.shared.zoomToFit()
            
        }
         let zoomTo1 = UIAction(title: "Zoom 1:1", image: nil) { _ in
             
             EditorModel.shared.zoomTo1of1()
             
         }*/
         
         /*
         let rotateLeftAction = UIAction(title: "Rotate left", image: nil) { _ in
             EditorModel.shared.rotateDrawing( byDegrees: -5)
         }
         let rotateRightAction = UIAction(title: "Rotate right", image: nil) { _ in
             EditorModel.shared.rotateDrawing( byDegrees: +5)
         }*/
         /*let layersMenu = UIAction(title: "Layers", image: nil) { _ in
             
             EditorModel.shared.showLayerEditorDetail = true
             
         }
        let editMenu = UIMenu(title: "Edit", children: [zoomToFitAction,zoomTo1].reversed())
          */
        // Creiamo il sottomenu "Layers"
        //let layersMenu = UIMenu(title: "Layers", children: [newLayerAction, viewLayersAction].reversed())
      
        // --- Menu Principale e Bottone ---
        /* let closeMenu = UIAction(title: "Exit", image: nil) { _ in
             EditorModel.shared.exit()
             
         }*/
        // Creiamo il menu principale che contiene i nostri due sottomenu
        /*self.mainMenu = UIMenu(title: "Project", options: .displayInline, children: [ saveAction, saveAsAction,saveToGallery,renameAction,publishAction,deleteMenu].reversed())  //,editMenu,closeMenu
        */
         
         let panAction = UIAction(title: "Pan", image: nil,state:isPanEnabled ? .on:.off) { _ in
             self.isPanEnabled.toggle()
         }
         let zoomAction = UIAction(title: "Zoom", image: nil,state:isZoomEnabled ? .on:.off) { _ in
             self.isZoomEnabled.toggle()
             
         }
         let rotationAction = UIAction(title: "Rotation", image: nil,state:isRotationEnabled ? .on:.off) { _ in
             self.isRotationEnabled.toggle()
             
         }
         let projectMenu = UIMenu(title: "Project", children: [ saveAction, saveAsAction,saveToGallery,renameAction,publishAction,deleteMenu].reversed())
         
         let gestureMenu = UIMenu(title: "Gestures", children: [ panAction, zoomAction,rotationAction].reversed())
        // projectMenu,
         self.mainMenu = UIMenu(title: "", options: .displayInline, children: [ panAction, zoomAction,rotationAction].reversed())
        // Assegniamo il bottone come accessoryItem del picker
         if let menuButton = menuButton {
             DispatchQueue.main.async{
                 menuButton.menu = self.mainMenu
             }
         }
    }
   
}
