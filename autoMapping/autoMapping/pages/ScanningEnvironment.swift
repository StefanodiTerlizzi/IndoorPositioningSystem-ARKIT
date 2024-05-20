//
//  ScanningEnvironment.swift
//  autoMapping
//
//  Created by student on 06/12/23.
//

import SwiftUI
import ARKit

struct ScanningEnvironment: View {
    
    @State private var messagesFromWorldMap: String = ""
    @State private var worlMapNewFeatures: Int = 0
    @State private var worldMapCounter: Int = 0
    @State var isScanningRoom = true
    
    @State private var showMapNameAlert = false
    @State private var cont = 1
    
    var roomcaptureView = RoomCaptureViewContainer()
    
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
    
    @State var signDoor = false
    
    @State var indexMapLoaded = -1
    
    @State var fileExist = FileManager().fileExists(atPath: Model.shared.usdzURL!.absoluteString)
    
    @State var timeLoading: Double = 0.0
    
    @State var message = ""
    @State var message2 = ""
    @State var message3 = "m3"
    @State var trackingState = ""
    
    @State private var mapName: String = ""
    @State private var showMergeButton = true
    @State private var showContinueButton = false
    @State private var showSaveButton = true
    @State private var showAlertForMapName = false

    
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
    
    
    var body: some View {
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
                    roomcaptureView.redoCapture()
                }.buttonStyle(.bordered)
                    .frame(width: 150, height: 70)
                    .background(Color(red: 255/255, green: 30/255, blue: 30/255))
                    .cornerRadius(6)
                    .bold()
                    .padding(.leading)
                
            }
            
            Text(message).bold().foregroundColor(.green).font(.title2)
            
            roomcaptureView
                .border(Color.white)
                .cornerRadius(6)
                .padding()
                .shadow(color: Color.white, radius: 20)
            
            
            HStack {
                
                if showSaveButton{
                    Button("SAVE ROOM"){
                        isScanningRoom = false
                        let finalMapName = "\(mapName)\(cont)"
                        roomcaptureView.stopCapture( pauseARSession: false,mapName: finalMapName)
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
                        roomcaptureView.continueCapture()
                        
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
                        roomcaptureView.stopCapture(pauseARSession: true, mapName: self.mapName)
                        convertMaptoJSON()
                        
                        if #available(iOS 17.0, *) {
                            
                            mergeSelectedRooms(mapName: self.mapName)
                            
                        } else {
                            print("Error: you have not iOS 17.0")
                        }
                    }.buttonStyle(.bordered).background(Color(red: 240/255, green: 151/255, blue: 45/255)).cornerRadius(6).bold()
                    
                }
                
            }
            
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(red: 11/255, green: 121/255, blue: 157/255)).foregroundColor(.white).alert("Write Global Map Name:", isPresented: $showAlertForMapName) {
            
            TextField("Map name:", text: $mapName)
            Button("OK") {
                print("Nome mappa Salvato: " + mapName)
            }
            Button("Annulla", role: .cancel) {
                //presentationMode.wrappedValue.dismiss()
            }
        }
        .onAppear {
            self.showAlertForMapName = true
        }.onReceive(NotificationCenter.default.publisher(for: .genericMessage)) { notification in
            if let message = notification.object as? String, message == "finish marging" {
                
                self.message = "Map: \(mapName), CREATED!"
            }
        }
    }
}

#Preview {
    ScanningEnvironment()
}
