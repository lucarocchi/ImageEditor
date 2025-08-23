//
//  EditingActionsPanel.swift
//  PKEditor
//
//  Created by Luca Rocchi on 25/06/25.
//


import SwiftUI



struct ActionsPanel: View {
    
    @ObservedObject var model = EditorModel.shared
    
    private var backgroundColorBinding: Binding<Color> {
        Binding<Color>(
            // GET: Convert the model's UIColor to a SwiftUI Color
            get: { Color(self.model.backgroundColor) },
            
            // SET: Convert the ColorPicker's new Color back to a UIColor
            set: { newColor in
                // We need to get the UIColor components from the new SwiftUI Color.
                // This requires a bit of code.
                let uiColor = UIColor(newColor)
                self.model.originalBackgroundColor = uiColor
                self.model.backgroundColor = uiColor
           
            }
        )
    }
    
    
    var body: some View {
        
        //ScrollView(.horizontal, showsIndicators: false){
            HStack(spacing: 10) {
                
                ColorPicker("Background", selection: backgroundColorBinding, supportsOpacity: true)
                    .labelsHidden()
                
                if model.backgroundImage != nil {
                   MenuImageFilter()
                }
                
                if UIDevice.current.userInterfaceIdiom == .phone {
                    Button() {
                        model.undo()
                    } label:{
                        Image(systemName: "arrow.uturn.backward")
                    }
                    Button() {
                        model.redo()
                    } label:{
                        Image(systemName: "arrow.uturn.forward")
                    }
                }
                
                Button() {
                    model.zoomToFit()
                } label:{
                    Image(systemName: "square.arrowtriangle.4.outward")
                }
                
               
                
                //}
         
                
                Button(action: {
                    model.showLayers = true
                }) {
                    Image(systemName: "square.3.layers.3d.bottom.filled")
                    
                }
                
                MenuProject()
                
                
                
                Button() {
                    //model.onExit?()
                    model.exit()
             } label:{
                    Image(systemName: "xmark.circle.fill")
                }
            
                
            }
            .font(.title3) // Sets a nice size for all icons
            .foregroundColor(Color(uiColor:.secondaryLabel)) // Adapts to light/dark mode
            .padding(.vertical, 8)
            .padding(.horizontal, 15)
            .background(Color(uiColor:.tertiarySystemBackground)) // Modern "frosted glass" effect
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.20), radius: 10, y: 0)
        //}
        
    }
   
}

