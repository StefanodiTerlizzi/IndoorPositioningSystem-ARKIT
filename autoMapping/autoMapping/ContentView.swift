//
//  ContentView.swift
//  autoMapping
//
//  Created by Stefano di Terlizzi on 08/07/23.
//

import SwiftUI
import RealityKit
import SceneKit
import ARKit
import RoomPlan
import CoreMotion

enum Page: String, CaseIterable {
    case ScanningRoom
    //case VisualizeRoom
    //case ExportPlanimetry
    //case CheckRotoTraslation
    case WorldMap
    case ConvertionLocalGlobal
}

struct ContentView : View {
    
    @State var page: Page? = nil

    //var arscnViewContainer = ARSCNViewContainer()
    //var scnViewContainer = SCNViewContainer()
    //var delegate = RenderDelegate()
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
    

    
    //@State var image: UIImage?
    
    @State var signDoor = false
    
    @State var indexMapLoaded = -1
    
    //let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
    //let url = NSURL(fileURLWithPath: Model.shared.usdzURL!.absoluteString)
    @State var fileExist = FileManager().fileExists(atPath: Model.shared.usdzURL!.absoluteString)
    
    @State var timeLoading: Double = 0.0
    
    @State var message = ""
    @State var message2 = ""
    @State var message3 = "m3"
    @State var trackingState = ""
    
    let list = listOfFilesURL(path: ["Maps"])
    
    @State var rotoTrasl: [DictToRototraslation]? = [DictToRototraslation(name: "a", traslation: simd_float4x4([
        simd_float4(0.9633633645810281,-0.0021981453897478684,-0.2428738157839862,0.8124287331481945),
        simd_float4(0.001960235951444359,0.9935070065595117,-0.0012164890794876995,-0.016000276236015493),
        simd_float4(0.24287585246714583,0.000700376692486864,0.9633651043162986,0.42286039590954916),
        simd_float4(0.0,0.0,0.0,1.0)
    ]).inverse, r_Y: simd_float4x4([
        simd_float4(0.9733228355953701,0.0,0.2294398782003427,0.0),
        simd_float4(0.0,
                    1.0,
                    0.0,
                    0.0),
        simd_float4(-0.2294398782003427,
                     0.0,
                     0.9733228355953701,
                     0.0),
        simd_float4(0.0,
                    0.0,
                    0.0,
                    1.0)
    ]).inverse
    ), DictToRototraslation(name: "b", traslation: simd_float4x4([
        simd_float4(-0.3219630897795689,0.0,-0.9458653570883789,0.13220344165005649),
        simd_float4(0.0,0.9991603999960835,0.0,-0.33440727146570937),
        simd_float4(0.9458653570883789,0.0,-0.3219630897795689,3.7942981785068692),
        simd_float4(0.0,0.0,0.0,1.0)
    ]).inverse, r_Y: simd_float4x4([
        simd_float4(-0.3156047007681471,
                     0.0,
                     0.9488907591778141,
                     0.0),
        simd_float4(0.0,
                    1.0,
                    0.0,
                    0.0),
        simd_float4(-0.9488907591778141,
                     0.0,
                     -0.3156047007681471,
                     0.0),
        simd_float4(0.0,
                    0.0,
                    0.0,
                    1.0)
    ]).inverse)]//calculateRotos()
    
    @State var indexRotoTrasl = -1
    
    @State private var selection = "none"
    
    var containerWidth:CGFloat = UIScreen.main.bounds.width - 32.0
    
    let colors = [UIColor(red: 0, green: 255, blue: 0, alpha: 0.5), UIColor(red: 255, green: 255, blue: 0, alpha: 0.5)]
    
    @State var mapsAvailable: [URL]? = Model.shared.mapsAvailable
    @State var indexMapLoadedForVisualization = -1
    @State var simdWorldTransform: [simd_float4x4] = []
    
    @State var selectedNode: SCNNode?
    
    
    var body: some View {
        //let _ = calculateRotos()
        //let _ = print("mapsAvailable")
        //let _ = print(mapsAvailable)
        /*Text(message)
        .onReceive(
            NotificationCenter.default.publisher(for: .genericMessage),
            perform: {msg in if let m = msg.object as? String {message=m}}
        )
        
        Text(message2)
        .onReceive(
            NotificationCenter.default.publisher(for: .genericMessage2),
            perform: {msg in if let m = msg.object as? String {message2=m}}
        )
        
        Text(message3)
        .onReceive(
            NotificationCenter.default.publisher(for: .genericMessage3),
            perform: {msg in if let m = msg.object as? String {message3=m}}
        )*/
        VStack{
            /*Text(message3)
            .onReceive(
                NotificationCenter.default.publisher(for: .genericMessage3),
                perform: {msg in if let m = msg.object as? String {message3=m}}
            )*/
            
            Text("page: \(page?.rawValue ?? "HOME")")
            HStack{
                ForEach(Page.allCases, id: \.rawValue){ p in
                    Button(String(p.rawValue.first!)){page = p}
                        .buttonStyle(.bordered)
                        //.disabled(p != .ScanningRoom && p != .VisualizeRoom && p != .WorldMap && p != .CheckRotoTraslation && p != .ConvertionLocalGlobal && !fileExist)
                }
                .frame(width: containerWidth * 0.10)
            }
        }.frame(width: 100, height: 100, alignment: .bottom)
        
        
        
            
        if page == nil {Text("AUTOMAPPING HOMEPAGE").frame(width: containerWidth * 0.90)}
        
        if page == .ScanningRoom {
            ScanningEnvironment().frame(width: containerWidth * 0.90)
                /*VStack {
                    /*Button("merging"){if #available(iOS 17.0, *) {mergeSelectedRooms()}}*/
                    /*Button("convert worldMap to JSON"){
                     guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                     print("error")
                     return
                     }
                     guard var list = try? FileManager.default.contentsOfDirectory(at: documentsDirectory.appending(path: "Maps"), includingPropertiesForKeys: nil) else {
                     print("error 2")
                     return
                     }
                     guard let listJson = try? FileManager.default.contentsOfDirectory(at: documentsDirectory.appending(path: "JsonMaps"), includingPropertiesForKeys: nil) else {
                     print("error 2")
                     return
                     }
                     list = list.filter({ URL in !(listJson.map{$0.lastPathComponent}.contains([URL.lastPathComponent]))})
                     var i = 0
                     for u in list {
                     print("read \(u.lastPathComponent)")
                     guard let mapData = try? Data(contentsOf: u), let worldMap = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: mapData) else {
                     print("error 3")
                     return
                     }
                     let jsonFile = documentsDirectory.appending(path: "JsonMaps").appending(path: "\(u.lastPathComponent)")
                     let decod = ARWorldMapCodable(
                     anchors: worldMap.anchors.map{a in AnchorCodable(x: a.transform.columns.3.x, y: a.transform.columns.3.y, z: a.transform.columns.3.z)},
                     center: worldMap.center,
                     extent: worldMap.extent,
                     rawFeaturesPoints: worldMap.rawFeaturePoints.points
                     )
                     
                     try? JSONEncoder().encode(decod).write(to: jsonFile)
                     print("write \(u.lastPathComponent)")
                     i = i+1
                     NotificationCenter.default.post(name: .genericMessage, object: "converted \(i) of \(list.count)")
                     }
                     }.buttonStyle(.bordered) */
                    Text("scanning")
                    Text("worldMapCounter: \(worldMapCounter)")
                        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.worldMapCounter), perform: {coutner in
                            if let counter = coutner.object as? Int {worldMapCounter = counter}
                        })
                    Text(messagesFromWorldMap)
                        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.worldMapMessage), perform: {message in
                            if let worldMap = message.object as? ARWorldMap {
                                /*messagesFromWorldMap = """
                                 x: \(worldMap.extent.x) y: \(worldMap.extent.y) z: \(worldMap.extent.z)\n
                                 mapDimension in m3: \(worldMap.extent.x * worldMap.extent.y * worldMap.extent.z)\n
                                 mapDimension in m2: \(worldMap.extent.x * worldMap.extent.z)\n
                                 anchors: \(worldMap.anchors.count)\n
                                 features:\(worldMap.rawFeaturePoints.identifiers.count)
                                 """*/
                                messagesFromWorldMap = """
                                mapDimension in m2: \(worldMap.extent.x * worldMap.extent.z)\n
                                anchors: \(worldMap.anchors.count)\n
                                features:\(worldMap.rawFeaturePoints.identifiers.count)
                                """
                                /*do {
                                 let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
                                 let formatter = DateFormatter()
                                 formatter.dateFormat = "yyyMMdd'T'HHmmss"
                                 let dateString = formatter.string(from: Date())
                                 try data.write(to: Model.shared.directoryURL.appending(path: "Maps").appending(path: dateString), options: [.atomic])
                                 //self.showAlert(message: "Map Saved")
                                 print("map saved in \(Model.shared.worldMapURL!)")
                                 } catch {
                                 fatalError("Can't save map: \(error.localizedDescription)")
                                 }*/
                            }
                        })
                    Text("new features: \(worlMapNewFeatures)")
                        .onReceive(NotificationCenter.default.publisher(for: .worlMapNewFeatures), perform: {message in
                            if let n = message.object as? Int {worlMapNewFeatures = n}
                        })
                    
                    roomcaptureView
                    HStack {
                        /*Button("redo"){
                         isScanningRoom = true
                         roomcaptureView.redoCapture()
                         }.buttonStyle(.bordered)*/
                        Button("save room"){
                            isScanningRoom = false
                            roomcaptureView.stopCapture(pauseARSession: false)
                            isScanningRoom = true
                        }.buttonStyle(.bordered)
                        Button("continue"){
                            isScanningRoom = true
                            roomcaptureView.continueCapture()
                        }.buttonStyle(.bordered)
                        Button("complete scan and merge"){
                            isScanningRoom = false
                            roomcaptureView.stopCapture(pauseARSession: true)
                            convertMaptoJSON()
                            //mergeSelectedRooms()
                        }.buttonStyle(.bordered)
                        
                    }
                    /* !isScanningRoom ?
                     Button("save")
                     {
                     let ok = roomcaptureView.saveResult()
                     if (ok) {
                     fileExist = true
                     page = .VisualizeRoom
                     }
                     }
                     .buttonStyle(.bordered)
                     : nil */
                }
                .frame(width: containerWidth * 0.90)*/
        }
        /* if page == .VisualizeRoom {
            VStack {
                Text("\(indexMapLoadedForVisualization) \(indexMapLoadedForVisualization != -1 ? mapsAvailable![indexMapLoadedForVisualization].lastPathComponent : "")")
                
                HStack{
                    Button("<"){
                        indexMapLoadedForVisualization -= 1
                        visualizeRoom.setup(cameraNodeVisualization, mapsAvailable![indexMapLoadedForVisualization])
                    }.buttonStyle(.bordered).disabled(indexMapLoadedForVisualization == -1)
                    Button(">"){
                        indexMapLoadedForVisualization += 1
                        visualizeRoom.setup(cameraNodeVisualization, mapsAvailable![indexMapLoadedForVisualization])
                    }.buttonStyle(.bordered).disabled(mapsAvailable != nil && indexMapLoadedForVisualization == mapsAvailable!.count-1)
                }
                visualizeRoom.sceneView
                    .gesture(
                        SpatialTapGesture(count: 1)
                        .onEnded(){ event in
                            // hit test
                            guard let renderer = visualizeRoom.delegate.lastRenderer else { return }
                            let hits = renderer.hitTest(event.location, options: nil)
                            if let tappedNode = hits.first?.node {
                                dimensions = []
                                print(tappedNode)
                                simdWorldTransform.append(tappedNode.simdWorldTransform)
                                selectedNode = tappedNode
                                //tappedNode.name! += "_tapped"
                                let angle = tappedNode.eulerAngles.y
                                tappedNode.eulerAngles.y -= angle
                                print(tappedNode)
                                print(tappedNode.boundingBox.min)
                                print(tappedNode.boundingBox.max)
                                tappedNode.eulerAngles.y = angle
                                dimensions.append(tappedNode.name ?? "no name")
                                dimensions.append(String(tappedNode.scale.x))
                                dimensions.append(String(tappedNode.scale.y))
                                dimensions.append(String(tappedNode.scale.z))
                                showingAlert = true
                                
                                //print(tappedNode.accessibilityPath?.currentPoint)
                                // do something
                                //print(renderer.projectPoint(renderer.scene?.rootNode.childNodes[0].accessibilityPath?.currentPoint))
                            }
                        }
                    )
                    /*.alert("\(selectedNode?.name ?? "no name")", isPresented: $showingAlert) {
                        if simdWorldTransform.count == 0 {
                            Button("add local", role: .cancel) {
                                if let tr = selectedNode?.simdWorldTransform {simdWorldTransform.append(tr)}
                            }
                        } else {
                            Button("add global", role: .cancel) {
                                if let tr = selectedNode?.simdWorldTransform {simdWorldTransform.append(tr)}
                            }
                        }
                    }*/
                /*HStack {
                    Button("zoom in"){
                        var orthographicScale = cameraNode.camera!.orthographicScale
                        cameraNode.camera!.orthographicScale = orthographicScale>5 ? orthographicScale-5 : orthographicScale
                    }.buttonStyle(.borderedProminent)
                    Button("zoom out"){
                        cameraNode.camera?.orthographicScale += 5
                    }.buttonStyle(.borderedProminent)
                }*/
                /*Button("to top View"){
                    guard let renderer = visualizeRoom.delegate.lastRenderer else { return }
                    print(
                        renderer.scene!.rootNode
                            .childNodes(passingTest: {
                                n,_ in n.name != nil && n.name! != "Room" && String(n.name!.suffix(4)) != "_grp"
                            })
                            .map{($0.name, $0.worldPosition, $0.scale)}
                    )
                }.buttonStyle(.bordered)*/
                if (dimensions.count > 0) {
                    Text("tap to an element to see the dimensions")
                    .alert("\(dimensions[0]) Dimesions:\nx: \(dimensions[1])\ny: \(dimensions[2])\nz: \(dimensions[3])", isPresented: $showingAlert) {
                        Button("OK", role: .cancel) { }
                    }
                } else {
                    Text("tap to an element to see the dimensions")
                }
                if simdWorldTransform.count == 2 {Button("create rotoConnection"){
                    //implement
                    let lPosition = simdWorldTransform[0]
                    print("lPosition",lPosition)
                    print(lPosition[0])
                    print(lPosition[1])
                    print(lPosition[2])
                    print(lPosition[3])
                    let gPosition = simdWorldTransform[1]
                    print("gPosition",gPosition)
                    print(gPosition[0])
                    print(gPosition[1])
                    print(gPosition[2])
                    print(gPosition[3])
                    var rototrasl = simd_mul(gPosition, lPosition.inverse)
                    //rototrasl[3][3] = 1.0
                    //rototrasl[1][1] = 1.0
                    // COMPUTE ROTOTRASLATION
                    //rotoTrasl?.append(DictToRototraslation(name: selectedNode?.name ?? "no name", traslation: rototrasl)))
                    print("rototrasl",rototrasl)
                    print(rototrasl[0])
                    print(rototrasl[1])
                    print(rototrasl[2])
                    print(rototrasl[3])
                    simdWorldTransform.removeAll()
                }}
                /*Button("overwrite scene"){
                    visualizeRoom.delegate.lastRenderer.scene!.write(to: Model.shared.usdzURL!, delegate: nil)
                }.buttonStyle(.borderedProminent)*/
            }
            .frame(width: containerWidth * 0.90)
        } */
        
        
        /* if page == .ExportPlanimetry {
            
            let _ = exportRoom.setupCamera(cameraNode: cameraNodePlanimetry)
            VStack {
                exportRoom
                HStack {
                    Button("zoom in"){
                        let orthographicScale = cameraNodePlanimetry.camera!.orthographicScale
                        cameraNodePlanimetry.camera!.orthographicScale = orthographicScale>5 ? orthographicScale-5 : orthographicScale
                    }.buttonStyle(.bordered)
                    Button("zoom out"){
                        cameraNodePlanimetry.camera?.orthographicScale += 5
                    }.buttonStyle(.bordered)
                    Button("export"){
                        let image = exportRoom.scnView.snapshot()
                        //image = visualizeRoom.sceneView.snapshot()
                        //image = visualizeRoom.sceneView.takeScreenshot(origin: geometry.frame(in: .global).origin, size: geometry.size)
                        ImageSaver().writeToPhotoAlbum(image: image)
                        showFeedbackExport = true
                    }.buttonStyle(.bordered)
                        .alert("image saved to gallery", isPresented: $showFeedbackExport) {
                            Button("OK", role: .cancel) { }
                        }
                }
                    /*Button("<-"){
                        exportRoom.scnView.pointOfView?.worldPosition.x += 1
                        //print(visualizeRoom.delegate.lastRenderer.pointOfView?.rotation)
                        //visualizeRoom.delegate.lastRenderer.pointOfView?.rotation.x += 1
                        //visualizeRoom.delegate.lastRenderer.pointOfView?.rotation.y += 1
                        //visualizeRoom.delegate.lastRenderer.pointOfView?.rotation.z = 1
                        //visualizeRoom.delegate.lastRenderer.pointOfView?.rotation.w += 1
                    }.buttonStyle(.bordered)
                    Button("->"){
                        print(exportRoom.scnView.pointOfView?.worldRight)
                        //exportRoom.scnView.pointOfView?.worldPosition.x += 5
                        /*var rotation = cameraNode.rotation
                        rotation.y += Float.pi / 2
                        cameraNode.rotation = rotation*/
                    }.buttonStyle(.bordered)*/
            }
            .frame(width: containerWidth * 0.90)
        } */
        
        /*if page == .CheckRotoTraslation {
            if let l = list, let rotos = rotoTrasl {
                VStack {
                    if indexMapLoaded != -1 {Text(l[indexMapLoaded].lastPathComponent)}
                    if indexRotoTrasl != -1 {Text(rotos[indexRotoTrasl].name)}
                    
                    HStack{
                        Text("Map Selector")
                        Button("<"){
                            NotificationCenter.default.post(name: .genericMessage, object: "loading map")
                            indexMapLoaded = indexMapLoaded-1
                            /*exportRoom.loadMap(
                                name: l[indexMapLoaded].lastPathComponent,
                                cameraNode: cameraNodePlanimetry
                            )*/
                        }.buttonStyle(.bordered).disabled(indexMapLoaded<1)
                        
                        Button(">"){
                            NotificationCenter.default.post(name: .genericMessage, object: "loading map")
                            indexMapLoaded = indexMapLoaded+1
                            /*exportRoom.loadMap(
                                name: l[indexMapLoaded].lastPathComponent,
                                cameraNode: cameraNodePlanimetry
                            )*/
                        }.buttonStyle(.bordered).disabled(indexMapLoaded == l.count-1)
                        
                    
                    }
                    HStack{
                        Text("Roto Selector")
                        Button("<<"){
                            NotificationCenter.default.post(name: .genericMessage, object: "loading features points")
                            indexRotoTrasl = 0
                            if let rotos = rotoTrasl, let map = worldTracking.getWorldMap(url: l[indexMapLoaded]) {
                                exportRoom.loadFeaturesPoints(
                                    colors[indexRotoTrasl % 2],
                                    rotos[indexRotoTrasl],
                                    map: map
                                )
                            }
                        }.buttonStyle(.bordered).disabled(indexRotoTrasl<1)
                        
                        Button("<"){
                            NotificationCenter.default.post(name: .genericMessage, object: "loading features points")
                            indexRotoTrasl = indexRotoTrasl-1
                            if let rotos = rotoTrasl, let map = worldTracking.getWorldMap(url: l[indexMapLoaded]) {
                                exportRoom.loadFeaturesPoints(
                                    colors[indexRotoTrasl % 2],
                                    rotos[indexRotoTrasl],
                                    map: map
                                )
                            }
                        }.buttonStyle(.bordered).disabled(indexRotoTrasl<1)
                        
                        Button(">"){
                            NotificationCenter.default.post(name: .genericMessage, object: "loading features points")
                            indexRotoTrasl = indexRotoTrasl+1
                            if let rotos = rotoTrasl, let map = worldTracking.getWorldMap(url: l[indexMapLoaded]){
                                exportRoom.loadFeaturesPoints(
                                    colors[indexRotoTrasl % 2],
                                    rotos[indexRotoTrasl],
                                    map: map
                                )
                            }
                        }.buttonStyle(.bordered).disabled(indexRotoTrasl == rotos.count-1)
                        
                        Button(">>"){
                            NotificationCenter.default.post(name: .genericMessage, object: "loading features points")
                            indexRotoTrasl = rotos.count-1
                            if let rotos = rotoTrasl, let map = worldTracking.getWorldMap(url: l[indexMapLoaded]){
                                exportRoom.loadFeaturesPoints(
                                    colors[indexRotoTrasl % 2],
                                    rotos[indexRotoTrasl],
                                    map: map
                                )
                            }
                        }.buttonStyle(.bordered).disabled(indexRotoTrasl == rotos.count-1)
                        
                    
                    }
                    
                    if indexMapLoaded != -1 {
                        exportRoom //ortographic View
                    }
                    
                }
                .frame(width: containerWidth * 0.90)
            } else {
                let _ = print(list)
                let _ = print(rotoTrasl)
                Text("no maps availables")
                    .frame(width: containerWidth * 0.90)
            }
        }  */
    
        if page == .WorldMap {
            Navigation()
            /*if let l = list {
                //let _ = print(l)
                //let _ = print(rotoTrasl)
                VStack {
                    Text(trackingState)
                    .onReceive(
                        NotificationCenter.default.publisher(for: .trackingState),
                        perform: {msg in if let m = msg.object as? ARCamera.TrackingState {
                            trackingState=trackingStateToString(m)
                            Model.shared.statusLocalSession = m
                            if Model.shared.statusLocalSession == .normal {globalView.drawOrigin(worldTracking.sceneView.scene.rootNode.worldPosition, UIColor(red: 50, green: 0, blue: 255, alpha: 1.0), 0.2, true)}
                        }}
                    )
                    if indexMapLoaded != -1 {Text(l[indexMapLoaded].lastPathComponent)}
                    
                    //map
                    HStack{
                        Button("<"){
                            Model.shared.updateRotos(
                                (indexMapLoaded == -1) ? nil : rotoTrasl![indexMapLoaded],
                                rotoTrasl![indexMapLoaded-1]
                            )
                            indexMapLoaded = indexMapLoaded-1
                            if let map = worldTracking.getWorldMap(url: l[indexMapLoaded]){
                                worldTracking.loadWorldMap(worldMap: map, l[indexMapLoaded].lastPathComponent)
                                globalView.loadgeneralMap()
                                globalView.drawOrigin(worldTracking.sceneView.scene.rootNode.worldPosition, UIColor(red: 0, green: 255, blue: 0, alpha: 1.0), 0.3)
                                singleView.loadRoomMaps(name: l[indexMapLoaded].lastPathComponent)
                            }
                        }.buttonStyle(.bordered).disabled(indexMapLoaded<1)
                        
                        Button(">"){
                            Model.shared.updateRotos(
                                (indexMapLoaded == -1) ? nil : rotoTrasl![indexMapLoaded],
                                rotoTrasl![indexMapLoaded+1]
                            )
                            indexMapLoaded = indexMapLoaded+1
                            if let map = worldTracking.getWorldMap(url: l[indexMapLoaded]){
                                worldTracking.loadWorldMap(worldMap: map, l[indexMapLoaded].lastPathComponent)
                                globalView.loadgeneralMap()
                                globalView.drawOrigin(worldTracking.sceneView.scene.rootNode.worldPosition, UIColor(red: 0, green: 255, blue: 0, alpha: 1.0), 0.3)
                                singleView.loadRoomMaps(name: l[indexMapLoaded].lastPathComponent)
                            }
                        }.buttonStyle(.bordered).disabled(indexMapLoaded==l.count-1)
                        
                        Text("\(timeLoading)").onReceive(
                            NotificationCenter.default.publisher(for: .timeLoading),
                            perform: {msg in if let m = msg.object as? Double {timeLoading=m}}
                        )
                    }
                    //rotos
                    //Text("roto: \(indexRotoTrasl == -1 ? "-1" : rotoTrasl![indexRotoTrasl].name)")
                    HStack {
                        if indexRotoTrasl != -1, let roto = rotoTrasl?[indexRotoTrasl], let map = worldTracking.getWorldMap(url: l[indexMapLoaded]) {
                            Button("Load features point") {
                                globalView.loadFeaturesPoints(colors[indexRotoTrasl % 2],roto,map: map)
                                singleView.loadFeaturesPoints(colors[indexRotoTrasl % 2],nil,map: map)
                            }
                            Button("unload features point") {
                                globalView.unloadFeaturesPoints()
                                singleView.unloadFeaturesPoints()
                            }

                        }
                        
                    }
                    HStack {
                        if indexMapLoaded != -1, let rotos = rotoTrasl, let map = worldTracking.getWorldMap(url: l[indexMapLoaded]) {
                            Button("zoom in"){
                                globalView.zoomIn()
                                singleView.zoomIn()
                            }.buttonStyle(.bordered)
                            Button("zoom out"){
                                globalView.zoomOut()
                                singleView.zoomOut()
                            }.buttonStyle(.bordered)
                            /*Button("<<"){
                                indexRotoTrasl = 0
                                //globalView.loadFeaturesPoints(colors[indexRotoTrasl % 2],rotos[indexRotoTrasl],map: map)
                                //singleView.loadFeaturesPoints(colors[indexRotoTrasl % 2],nil,map: map)
                            }.buttonStyle(.bordered).disabled(indexRotoTrasl<1)
                            Button("<"){
                                indexRotoTrasl -= 1
                                /*if let rotos = rotoTrasl, let map = worldTracking.getWorldMap(url: l[indexMapLoaded]){
                                    globalView.loadFeaturesPoints(colors[indexRotoTrasl % 2],rotos[indexRotoTrasl],map: map)
                                    singleView.loadFeaturesPoints(colors[indexRotoTrasl % 2],nil,map: map)
                                }*/
                            }.buttonStyle(.bordered).disabled(indexRotoTrasl<1)
                            Button(">"){
                                indexRotoTrasl += 1
                                /*if let rotos = rotoTrasl, let map = worldTracking.getWorldMap(url: l[indexMapLoaded]){
                                    globalView.loadFeaturesPoints(colors[indexRotoTrasl % 2],rotos[indexRotoTrasl],map: map)
                                    singleView.loadFeaturesPoints(colors[indexRotoTrasl % 2],nil,map: map)
                                }*/
                            }.buttonStyle(.bordered).disabled(indexRotoTrasl==rotos.count-1)
                            Button(">>"){
                                indexRotoTrasl = rotoTrasl!.count - 1
                                /*if let rotos = rotoTrasl, let map = worldTracking.getWorldMap(url: l[indexMapLoaded]){
                                    globalView.loadFeaturesPoints(colors[indexRotoTrasl % 2],rotos[indexRotoTrasl],map: map)
                                    singleView.loadFeaturesPoints(colors[indexRotoTrasl % 2],nil,map: map)
                                }*/
                            }.buttonStyle(.bordered).disabled(indexRotoTrasl==rotos.count-1)*/
                        } else {
                            Text("no map")
                        }
                    }
                    
                    VStack{
                        if indexMapLoaded != -1 {
                            worldTracking //ARWorldMap ARSession
                            globalView //ortographic view
                            singleView //ortographic view
                                .onReceive(
                                    NotificationCenter.default.publisher(for: .trackingPosition),
                                    perform: {msg in if let m = msg.object as? simd_float4x4 {
                                        //print(m)
                                        guard indexMapLoaded != -1 else {return}
                                        if let roto = rotoTrasl?[indexMapLoaded] {
                                            NotificationCenter.default.post(name: .genericMessage, object: "update position with \(roto.name)")
                                            globalView.updatePosition(m, roto)
                                            singleView.updatePosition(m, nil)
                                        }
                                        //Model.shared.actualPosition = m
                                    }}
                                )
                                /*.onReceive(
                                    NotificationCenter.default.publisher(for: .trackingPositionFromMotionManager),
                                    perform: {msg in if let m = msg.object as? CMDeviceMotion {
                                        exportRoom.updatePositionFromMotionManager(m)
                                    }}
                                )*/
                            /*NotificationCenter.default.addObserver(forName: .trackingPosition, object: nil, queue: OperationQueue.current) { msg in
                                if let transform = msg.object as? simd_float4x4 {
                                    print(transform)
                                    //updatePosition(transform)
                                }
                            }*/
                        }
                    }
                }
                .frame(width: containerWidth * 0.90)
            } else {
                Text("no maps availables")
                    .frame(width: containerWidth * 0.90)
            }*/
        }
        
        if page == .ConvertionLocalGlobal {
            ConvertionLocalGlobal()
        }
        
        
        
        

            
    }
        
        
}
            




#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        if #available(iOS 17.0, *) {
            ContentView()
        } else {
            // Fallback on earlier versions
        }
    }
}
#endif

/*
extension View {
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)

        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

extension UIView {
    var renderedImage: UIImage {
        // rect of capure
        let rect = self.bounds
        // create the context of bitmap
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        self.layer.render(in: context)
        // get a image from current context bitmap
        let capturedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return capturedImage
    }
}

extension View {
    func takeScreenshot(origin: CGPoint, size: CGSize) -> UIImage {
        let window = UIWindow(frame: CGRect(origin: origin, size: size))
        let hosting = UIHostingController(rootView: self)
        hosting.view.frame = window.frame
        window.addSubview(hosting.view)
        window.makeKeyAndVisible()
        return hosting.view.renderedImage
    }
}
*/

final class ImageSaver: NSObject {
    static var error = ""
    func writeToPhotoAlbum(image: UIImage) {
        print(image)
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveError), nil)
    }

    @objc func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            ImageSaver.error = "\(error)"
            print("error: \(error)")
        } else {
            ImageSaver.error = "Save completed!"
            print("Save completed!")
        }
    }
}

