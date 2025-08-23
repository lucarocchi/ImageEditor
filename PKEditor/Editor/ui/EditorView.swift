//
//  ContentView.swift
//  PKEditor
//
//  Created by Luca Rocchi on 12/06/25.
//

import SwiftUI

import PencilKit
import PhotosUI


//https://stackoverflow.com/questions/70274330/how-do-i-create-a-pkdrawing-programmatically-from-cgpoints/70274331#70274331
//https://gemini.google.com/share/6d0c61a34ebf

struct EditorView: View {
    @StateObject var model = EditorModel.shared
    //@AppStorage("lastToolPickerState")
    //private var storedToolPickerStateData: Data?
    //@State private var toolPickerState: ToolPickerState = ToolPickerState()
     
    //@State var showEditorDetail = false
    @State var showHandles = false
    @State var selectedPhoto: PhotosPickerItem?
    @State var projectName = ""
    @State private var selectedPhotoItem: PhotosPickerItem?

    @State private var panelOffset: CGSize = .zero
    @State private var draggingOffset: CGSize = .zero

    //@State private var columnVisibility = NavigationSplitViewVisibility.all

    // State for the navigator's position
    @State private var navigatorOffset: CGSize = .zero
    @State private var navigatorDragOffset: CGSize = .zero
    @State private var contentSize: CGSize = .zero
  
    var body: some View {
        
        /*
        NavigationSplitView(columnVisibility: $columnVisibility) {
             } detail: {
             }
             .navigationSplitViewStyle(.balanced)
        */
        
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ZStack {
                    Color(uiColor: model.edgeColor) //.opacity(1.0)
                        //.ignoresSafeArea()
                        .overlay{
                            Color(uiColor: model.backgroundColor).opacity(1.0)
                                .frame(width:contentSize.width,height:contentSize.height)
                                .overlay{
                                    Rectangle().stroke(Color.black, lineWidth: 1)
                                        //.shadow(radius: 3, x: 3, y: 3)
                                    
                                }
                        }
                    
                    
             
                    
                    ForEach(Array(model.layers.enumerated()), id: \.element.id) { index, layer in
                        LayerContainerView(
                            index:index,
                            layer: layer,
                            activeCanvas: $model.activeCanvasId,
                            sharedOffset:$model.contentOffset
                            
                        )
                        .allowsHitTesting(model.activeCanvasId == layer.currentCanvasId)
                        .zIndex(Double(index))
                        //.id(model.activeCanvasId)
                    }.onAppear {
                        //model.setBackgroundColor()
                    }
                    
                    VStack{
                        ActionsPanel()
                        .padding(.top, 10)
                        .padding(.trailing, 10)
                        Spacer()
                    }
                    //.frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.top)// Add some space from the top edge
                    
                    .zIndex(1000)
                    .offset(y: panelOffset.height + draggingOffset.height)
                 
                    
                    if model.showTextInput {
                        TextInput()
                            .position(model.inputPosition)
                            .zIndex(Double(model.layers.count+1))
                    }
                   
                    if showHandles {
                        EditingHandlesView()
                    }
                    
                    if model.isShowingNavigator {
                       NavigatorView()
                           /*.offset(x: navigatorOffset.width + navigatorDragOffset.width,
                                   y: navigatorOffset.height + navigatorDragOffset.height)
                           .gesture(
                               DragGesture()
                                   .onChanged { value in
                                       self.navigatorDragOffset = value.translation
                                   }
                                   .onEnded { value in
                                       self.navigatorOffset.width += value.translation.width
                                       self.navigatorOffset.height += value.translation.height
                                       self.navigatorDragOffset = .zero
                                   }
                           )
                            */
                           .frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.topTrailing)
                           .padding(10)
                    }
                    
                }
                
                //.background(Color.gray)
                .id(model.projectId)
            }
            .onAppear() {
                model.newProject()
                DispatchQueue.main.async{
                    contentSize=model.convertCtoV(contentSize: model.contentSize) ?? .zero
                }
            }
            .onDisappear {
                // Save current state to UserDefaults
                /*if let encoded = try? JSONEncoder().encode(toolPickerState) {
                 storedToolPickerStateData = encoded
                 }*/
            }
            .sheet(isPresented: $model.showFontSheet) {
                FontBottomSheetView(isVisible:$model.showFontSheet)
                    .presentationDetents([.medium])
                    .background(.background)
                
            }
            /*.onChange(of: toolPickerState) { oldState, newState in
                /*if let encoded = try? JSONEncoder().encode(newState) {
                 storedToolPickerStateData = encoded
                 }*/
            }*/
            
            .onChange(of: model.activeCanvasId) { oldState, newState in
            }
            .sheet(isPresented: $model.showLayers){
                LayersListView(activeCanvas: $model.activeCanvasId)
            }
            .sheet(isPresented: $model.showProjects){
                ProjectsGridView(projects: model.recentProjects) {
                    project in
                    model.showProjects = false
                    model.loadProject(project.name)
                }
            }
            
            .alert("Rename".localize,isPresented: $model.showRenameProject) {
                TextField("New name".localize, text: $projectName)
                
                Button("Ok".localize){
                    if !projectName.isEmpty{
                        model.renameProject(to: projectName)
                    }
                }
                
                Button("Cancel".localize,role:.cancel){
                }
            } message:{
                Text("\(model.projectName)")
            }
            .alert("Save project as".localize,isPresented: $model.saveProjectAs) {
                TextField("Name".localize, text: $projectName)
                
                Button("Ok".localize){
                    if !projectName.isEmpty{
                        model.saveProject(name: projectName)
                    }
                }
                
                Button("Cancel".localize,role:.cancel){
                }
            }
            .alert("Delete Project?", isPresented: $model.showDeleteProject) {
                Button("Delete", role: .destructive) {
                    model.deleteProject()
                    model.newProject()
               }
                
                Button("Cancel", role: .cancel) {
                    // Non serve codice qui, l'alert si chiude da solo
                }
                    
            } message: {
                Text("This will permanently delete the project. This action cannot be undone.")
            }
            .photosPicker(
                       isPresented: $model.showPhotoPicker, // Usa la variabile che già hai
                       selection: $selectedPhotoItem,
                       matching: .images
                   )
            .onChange(of: selectedPhotoItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            if let image = UIImage(data: data) {
                                model.newProjectFromImage(image)
                                
                                print("✅ Immagine selezionata dalla galleria: \(image.size)")
                            }
                        }
                    }
                }
            .onChange(of: model.showGallery) { oldState, newState in
                let photosURL = URL(string: "photos-redirect://")
                if let url = photosURL {
                     if UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url)
                     }
                }
                model.showGallery = false
             
            }
            .fileImporter(
                isPresented: $model.showDocPicker,
                allowedContentTypes: [.json,.pdf]
            ) { result in
                switch result {
                case .success(let url):
                    DispatchQueue.main.async{
                        guard url.startAccessingSecurityScopedResource() else {
                            return
                        }
                        model.loadProject(from: url)
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
            .fullScreenCover(isPresented: $model.showCamera) {
                CameraPickerView() { photo in
                    // Do what you want with your image.
                    model.showCamera = false
                    model.newProjectFromImage(photo)
                    
               
                }
            }.onReceive(NotificationCenter.default.publisher(for: Notification.UnselectStroke))
            { obj in
                showHandles = false
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.SelectStroke))
            { obj in
               DispatchQueue.main.async{
                    showHandles = true
               }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.CanvasTransformed))
            { obj in
                DispatchQueue.main.async{
                    contentSize=model.convertCtoV(contentSize: model.contentSize) ?? .zero
                    model.updateEdgeInsets(geometrySize: geometry.size, contentSize: contentSize)
                    
                }
            }
  
        }
        
    }
    
    
}


extension String {
    var localize:String {
        return NSLocalizedString(self,comment: "")
    }
}

extension EditorView {
    /// Calculates the initial position of the panel (top-center).
       private func initialPanelOffset(in containerSize: CGSize) -> CGSize {
           // We'll place it near the top, centered horizontally.
           // You can adjust the vertical position with the '- 50'.
           let yOffset = (-containerSize.height / 2) + 50
           return CGSize(width: 0, height: yOffset)
       }

       /// Calculates which edge the panel should "snap" to.
       private func snapToEdge(proposedOffset: CGSize, panelSize: CGSize, containerSize: CGSize) -> CGSize {
           // Convert the offset to a center point for easier calculation
           let containerCenter = CGPoint(x: containerSize.width / 2, y: containerSize.height / 2)
           let proposedCenter = CGPoint(x: containerCenter.x + proposedOffset.width, y: containerCenter.y + proposedOffset.height)

           // Determine if we are in the top or bottom half
           let isTopHalf = proposedCenter.y < containerCenter.y
           
           let newY = (isTopHalf ? -containerSize.height / 2 : containerSize.height / 2) + (isTopHalf ? 50 : -50)

           // For simplicity, we just keep it centered horizontally.
           // A more complex implementation could snap to corners.
           let newX: CGFloat = 0

           return CGSize(width: newX, height: newY)
       }
   }

