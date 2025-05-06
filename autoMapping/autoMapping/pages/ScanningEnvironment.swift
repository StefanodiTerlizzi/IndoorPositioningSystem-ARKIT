//
//  ScanningEnvironment.swift
//  autoMapping
//
//  Created by Stefano di Terlizzi on 11/07/23.
//  Upgraded by Michel Attilio Iodice on 22/10/24.
//

import SwiftUI
import ARKit
import PhotosUI
import UIKit

struct ScanningEnvironment: View {
    
    @State private var messagesFromWorldMap: String = ""
    @State private var worlMapNewFeatures: Int = 0
    @State private var worldMapCounter: Int = 0
    @State private var worldImageFind: [String] = []
    @State private var worldImageToFind: [String] = []
    @State var isScanningRoom = true
    
    @State private var showMapNameAlert = false
    @State private var cont = 1
    
    var roomCaptureView = RoomCaptureViewContainer()
    
    var visualizeRoom = VisualizeRoomViewContainer()
    var exportRoom = SCNViewContainer()
    var globalView = SCNViewContainer()
    var singleView = SCNViewContainer()
    var worldTracking = ARSCNViewContainer()
    @State var cameraNodeVisualization = SCNNode()
    @State var cameraNodePlanimetry = SCNNode()
    
    
    @State private var showingAlert = false
    @State private var showFeedbackExport = false
    @State private var dimensions: [String] = []
    @State private var showError: Bool = false
    @State private var showError2: Bool = false
    
    @State var signDoor = false
    
    @State var indexMapLoaded = -1
    
    @State var fileExist = FileManager().fileExists(atPath: Model.shared.usdzURL!.absoluteString)
    
    @State var timeLoading: Double = 0.0
    
    @State var message = ""
    @State var message2 = ""
    @State var message3 = "m3"
    @State var trackingState = ""
    
    @State private var mapName: String = ""
    @State private var imageName: String = ""
    @State private var imageAuthor: String = ""
    @State private var selectedItem: PhotosPickerItem?=nil
    @State var selectedImage: UIImage?=nil
    @State private var imageDescription: String = ""
    @State private var imageWidth: String = ""
    @State private var imageHeight: String = ""
    @State private var showMergeButton = true
    @State private var showContinueButton = false
    @State private var showSaveButton = true
    @State private var showAlertForMapName = false
    @State private var showAlertForImages = false

    
    let list = listOfFilesURL(path: ["Maps"])
    @State var rotoTrasl: [DictToRototraslation]?
    
    @State var indexRotoTrasl = -1
    
    @State private var selection = "none"
    
    var containerWidth:CGFloat = UIScreen.main.bounds.width - 32.0
    
    let colors = [UIColor(red: 0, green: 255, blue: 0, alpha: 0.5), UIColor(red: 255, green: 255, blue: 0, alpha: 0.5)]
    
    @State var mapsAvailable: [URL]? = Model.shared.mapsAvailable
    @State var indexMapLoadedForVisualization = -1
    @State var simdWorldTransform: [simd_float4x4] = []
    
    @State var selectedNode: SCNNode?
    
    @State var errorMessage: String = ""
    
    func clearParameter(){
        selectedImage = nil
        imageName = ""
        imageAuthor = ""
        imageDescription = ""
        imageWidth = ""
        imageHeight = ""
    }
    func updateImageFindList(with name: String){
        worldImageFind.append(name)
    }
    func updateImageToFindList(with name: String){
        worldImageToFind.append(name)
    }
    func validateFields() {
        showError2 = (selectedImage == nil) || imageName.isEmpty || imageDescription.isEmpty || imageWidth.isEmpty || imageHeight.isEmpty || imageAuthor.isEmpty
        
        if showError2==false {
            showError2 = CoreDataManager.shared.isPresent(name: imageName, author: imageAuthor, image: selectedImage!)
            errorMessage = "Art Work already present"
        }
        
        if showError2==false {
            roomCaptureView.loadImages(
                mapName:mapName,
                image: selectedImage!,
                name:imageName,
                author: imageAuthor,
                description:imageDescription,
                width:imageWidth,
                height:imageHeight)
            clearParameter()
            showAlertForImages = true
        } else {
            errorMessage = "upload failed"
            showAlertForImages = true
        }
    }
    func validateParameter() {
        showError = mapName.isEmpty
        
        if showError==false {
            print("map name saved: " + mapName)
            showAlertForMapName = false
            showAlertForImages = true
        } else {
            errorMessage = "Map name is mandatory"
            showAlertForMapName = true
        }
    }
    func closeImageAlert() {
        clearParameter()
        showAlertForImages = false
    }
    
    
    var body: some View {
        ZStack{
            VStack {
                Text("SCANNING ROOM").bold().font(.largeTitle)
                HStack{
                    VStack{
                        
                        Text("WorldMapCounter: \(worldMapCounter)")
                            .onReceive(NotificationCenter
                                .default
                                .publisher(for: Notification.Name.worldMapCounter),
                                       perform: {coutner in
                                if let counter = coutner.object as? Int {worldMapCounter = counter}
                            })
                        
                        Text(messagesFromWorldMap)
                            .onReceive(NotificationCenter
                                .default
                                .publisher(for: Notification.Name.worldMapMessage), perform: {message in
                                    if let worldMap = message.object as? ARWorldMap {
                                        messagesFromWorldMap = """
                                        mapDimension in m2: \(worldMap.extent.x * worldMap.extent.z)\n
                                        anchors: \(worldMap.anchors.count)\n
                                        features:\(worldMap.rawFeaturePoints.identifiers.count)
                                        """
                                    }
                                })
                        
                        Text("new features: \(worlMapNewFeatures)")
                            .onReceive(NotificationCenter
                                .default
                                .publisher(for: .worlMapNewFeatures), perform: {message in
                                    if let n = message.object as? Int {worlMapNewFeatures = n}
                                })
                        
                    }
                    
                    Button("RESTART"){
                        isScanningRoom = true
                        roomCaptureView.redoCapture()
                    }.buttonStyle(.bordered)
                        .frame(width: 150, height: 70)
                        .background(Color(red: 255/255, green: 30/255, blue: 30/255))
                        .cornerRadius(6)
                        .bold()
                        .padding(.leading)
                    
                }
                
                HStack{
                    if !worldImageToFind.isEmpty {
                        Text("ArtWork:")
                        ScrollView{
                            ForEach(worldImageToFind, id:\.self){ val in
                                Text(val).font(.footnote)
                            }
                        }.frame(maxHeight:30)
                    }
                    
                    if !worldImageFind.isEmpty {
                        Text("ArtWork Found:")
                        ScrollView{
                            ForEach(worldImageFind, id:\.self){ val in
                                Text(val).font(.footnote)
                            }
                        }.frame(maxHeight:30)
                    }
                }
                Text(message).bold().foregroundColor(.green).font(.title2)
                
                roomCaptureView
                    .border(Color.white)
                    .cornerRadius(6)
                    .padding()
                    .shadow(color: Color.white, radius: 20)
                
                
                HStack {
                    
                    if showSaveButton{
                        Button("SAVE ROOM"){
                            isScanningRoom = false
                            let finalMapName = "\(mapName)\(cont)"
                            roomCaptureView.stopCapture( pauseARSession: false,mapName: finalMapName)
                            cont += 1
                            isScanningRoom = true
                            showMergeButton = true
                            showContinueButton = true
                            showSaveButton = false
                            
                            
                        }.buttonStyle(.bordered)
                            .background(Color(red: 255/255, green: 235/255, blue: 205/255))
                            .cornerRadius(6)
                            .bold()
                    }
                    
                    
                    if(showContinueButton){
                        Button("SCAN \(cont)° ROOM"){
                            isScanningRoom = true
                            roomCaptureView.continueCapture()
                            
                            showMergeButton = false
                            showContinueButton = false
                            showSaveButton = true
                            
                        }.buttonStyle(.bordered)
                            .background(Color(red: 255/255, green: 235/255, blue: 205/255))
                            .cornerRadius(6)
                            .bold()
                            
                    }
                    
                    
                    if showMergeButton{
                        Button("CREATE GLOBAL MAP"){
                            isScanningRoom = false
                            roomCaptureView.stopCapture(pauseARSession: true, mapName: self.mapName)
                            convertMaptoJSON()
                            
                            if #available(iOS 17.0, *) {
                                
                                mergeSelectedRooms(mapName: self.mapName)
                                
                            } else {
                                print("Error: you have not iOS 17.0")
                            }
                        }.buttonStyle(.bordered).background(Color(red: 240/255, green: 151/255, blue: 45/255)).cornerRadius(6).bold()
                        
                    }
                    
                    
                    
                }
                
            }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(red: 11/255, green: 121/255, blue: 157/255)).foregroundColor(.white).blur(radius: showAlertForMapName || showAlertForImages ? 3:0)
            .onAppear {
                self.showAlertForMapName = true
            }.onReceive(NotificationCenter.default.publisher(for: .genericMessage)) { notification in
                if let message = notification.object as? String, message == "finish marging" {
                    
                    self.message = "Map: \(mapName), CREATED!"
                }
            }.onReceive(NotificationCenter.default.publisher(for: Notification.Name("ArtWorkFound"))) { notification in
                if let userInfo = notification.userInfo,
                   let artWorkName = userInfo["artWorkName"] as? String {
                    self.updateImageFindList(with: artWorkName)
                    print("UI upgrade with new art work found")
                }
                
            }.onReceive(NotificationCenter.default.publisher(for: Notification.Name("ArtWorks"))) { notification in
                if let userInfo = notification.userInfo,
                   let artWorkName = userInfo["artWorksName"] as? String {
                    self.updateImageToFindList(with: artWorkName)
                    print("UI upgrade with new art work")
                }
                   
            }
            
            if showAlertForMapName {
                Color.black.opacity(0.4).ignoresSafeArea()
                VStack{
                    AlertForMapName.frame(maxWidth:300).background(Color.white.opacity(0.5)).cornerRadius(12).shadow(radius: 20).padding()
                }
            }
            
            if showAlertForImages {
                Color.black.opacity(0.4).ignoresSafeArea()
                VStack{
                    AlertForImages.frame(maxWidth:200).background(Color.white.opacity(0.5)).cornerRadius(12).shadow(radius: 20).padding()
                }
            }
        }
    }
    
    private var AlertForMapName: some View {
        VStack(spacing:20){
            
            Text("Write Global Map Name:").font(.headline).padding(.top)
            if showError {
                Text("\(errorMessage)").foregroundColor(.red).font(.caption)
            }
            TextField("Map name:", text: $mapName).textFieldStyle(RoundedBorderTextFieldStyle()).padding(.horizontal)
            Divider()
            VStack{
                Button(action: {validateParameter()}, label: {
                    Text("OK")
                }).frame(maxWidth:.infinity).foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                Divider()
                Button(action: {mapName=""}, label: {
                    Text("Canc")
                }).frame(maxWidth:.infinity).foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
            }
        }.padding()
    }
    
    private var AlertForImages: some View {
        VStack(spacing:20){
            Text("Insert Works of Art:").font(.headline).padding(.top)
            if showError2 {
                Text("\(errorMessage)").foregroundColor(.red).font(.caption)
            }
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                preferredItemEncoding:.current,
                photoLibrary:.shared()){
                 Text("Select Photo")
                }.onChange(of: selectedItem){
                    newItem in if let newItem = newItem{
                        newItem.loadTransferable(type:ProfileImage.self){result in switch result{
                        case .success(let image):
                            if let image=image{
                                selectedImage=image.image
                            }
                        case .failure(let error):
                            print("Error loading image: \(error)")
                        }}
                    }
                }.ignoresSafeArea()
            if let selectedImage=selectedImage{
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            }
            VStack(spacing:0){
                TextField("Image name:", text: $imageName).padding(.horizontal)
                Divider()
                TextField("Image author:", text: $imageAuthor).padding(.horizontal)
                Divider()
                TextField("Image description:", text: $imageDescription).padding(.horizontal)
                Divider()
                TextField("Image width in meters:", text: $imageWidth).keyboardType(.decimalPad).padding(.horizontal)
                Divider()
                TextField("Image height in meters:", text: $imageHeight).keyboardType(.decimalPad).padding(.horizontal)
            }.background(Color.white).cornerRadius(12)
            
            Divider()
            VStack{
                Button(action: {validateFields()}, label: {
                    Text("Load Image")
                }).frame(maxWidth:.infinity).foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                Divider()
                Button(action: {closeImageAlert()}, label: {
                    Text("OK")
                }).frame(maxWidth:.infinity).foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                Divider()
                Button(action: {clearParameter().self}, label: {
                    Text("Canc")
                }).frame(maxWidth:.infinity).foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
            }
            
        }.padding()
    }
}

#Preview {
    ScanningEnvironment()
}


struct ProfileImage: Transferable{
    let image: UIImage
    
    static var transferRepresentation: some TransferRepresentation{
        DataRepresentation(importedContentType: .image){
            data in let uiImage = UIImage(data:data)
            let image = uiImage
            return ProfileImage(image:image!)
        }
    }
}
