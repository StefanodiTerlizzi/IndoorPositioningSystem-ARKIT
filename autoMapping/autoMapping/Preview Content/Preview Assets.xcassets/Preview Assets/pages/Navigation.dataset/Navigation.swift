//
//  Navigation.swift
//  autoMapping
//
//  Created by student on 01/12/23.

import SwiftUI
import simd
import ARKit

struct Navigation: View {
    
    let colors = [UIColor(red: 0, green: 255, blue: 0, alpha: 0.5), UIColor(red: 255, green: 255, blue: 0, alpha: 0.5)]
    
    var boundingBoxesLocal: [[SCNNode]] = []
    var boundingBoxesGlobal: [[SCNNode]] = []
    
    //let list = listOfFilesURL(path: ["Maps"])
    let list: [URL]?
    var globalView = SCNViewContainer()
    var singleView = SCNViewContainer()
    var worldTracking = ARSCNViewContainer()
    
    @State var navMessage = ""
    
    @State var extractedWord = ""
    
    @State var trackingState = ""
    @State var indexMapLoaded = -1
    @State var indexRotoTrasl = -1
    @State var timeLoading: Double = 0.0
    @State var BBdetection = ""
    @StateObject var model: Model = Model.shared
    
    @State var switching = false
    
    @State var switchingList: [Date] = []
    
    @State private var switchAlert: Bool = false
    
    @State var indexToLoad: Int?
    
    @State var shouldSwitchMap = false
    
    var rotoTrasl: [DictToRototraslation]?
    
    //    func extractFileName(from path: String) -> String {
    //        let fileNameWithExtension = path as NSString
    //        let fileNameWithoutExtension = fileNameWithExtension.deletingPathExtension
    //
    //        if let range = fileNameWithoutExtension.range(of: "\\d+$", options: .regularExpression) {
    //            return String(fileNameWithoutExtension[..<range.lowerBound])
    //        } else {
    //            return fileNameWithoutExtension
    //        }
    //    }
    
    init() {
        
        list = listOfFilesURL(path: ["Maps"])
        rotoTrasl = createDictroto()
        
        if let _list = list {
            if rotoTrasl != nil {
                
                let names = _list.map{$0.lastPathComponent}
                rotoTrasl = rotoTrasl!.sorted {
                    guard let index1 = names.firstIndex(of: $0.name),
                          let index2 = names.firstIndex(of: $1.name)
                    else {
                        return false
                    }
                    return index1 < index2
                    
                }
            }
            
            
            let names = rotoTrasl?.map { $0.name } ?? []
            
            print(_list.map{$0.lastPathComponent})  //Print just the name of maps
            
            for (index, element) in _list.enumerated() {
                if let _r = rotoTrasl, _r.contains(where: {$0.name == element.lastPathComponent}) {
                    print("Call Bounding B \(index) to \(element)\n")
                    calculateBoundingBoxes(index: index, usdzMap: element)
                }
            }
        }
        
        print("checkAllRotos: \(checkAllRotos())")
    }
    
    mutating func calculateBoundingBoxes(index: Int, usdzMap: URL) {

        
        let scene = try! SCNScene(url: Model.shared.directoryURL
            .appending(path: "MapUsdz")
            .appending(path: "\(usdzMap.lastPathComponent).usdz"))
        scene.rootNode.childNodes
            .forEach{
                $0.simdTransform = $0.simdWorldTransform
                scene.rootNode.addChildNode($0)
            }
        
        
        let a = SCNNode()
        let b = SCNNode()
        let c = SCNNode()
        let d = SCNNode()
        
        a.simdWorldPosition = simd_float3(scene.rootNode.boundingBox.0.x, 2, scene.rootNode.boundingBox.0.z)
        b.simdWorldPosition = simd_float3(scene.rootNode.boundingBox.0.x, 2, scene.rootNode.boundingBox.1.z)
        c.simdWorldPosition = simd_float3(scene.rootNode.boundingBox.1.x, 2, scene.rootNode.boundingBox.0.z)
        d.simdWorldPosition = simd_float3(scene.rootNode.boundingBox.1.x, 2, scene.rootNode.boundingBox.1.z)
        
        
        boundingBoxesLocal.append([a,b,d,c])
        
        var success = true
        var conv: [SCNNode] = []
        for e in [a,b,d,c] {
            //conv.append(projectNode(e, rotoTrasl![index]))
            if let rotoTrasl = rotoTrasl, index < rotoTrasl.count {
                    conv.append(projectNode(e, rotoTrasl[index]))
                } else {
                    // rotoTrasl non è disponibile o l'indice è fuori dai limiti
                    success = false
                    break // Interrompe il ciclo poiché una condizione di fallimento è stata incontrata
                }
        }
        boundingBoxesGlobal.append(conv)
        
    }
    
    func checkAllRotos() -> Bool {
        if let _r = rotoTrasl, let _l = list {
            let maps = Set(_l.map{$0.lastPathComponent})  //Prendo solo il nome della mappa
            let rotos = Set(_r.map{$0.name})              //Prendo solo il nome della rotoTrasl
            
            print("Rotos_check: \(rotos)\n\n")
            return maps.isSubset(of: rotos)               //Guardo se la mappa è un sottoinsieme della roto
        }
        return false
    }
    
    
    //FROM Local Selection TO Global MAP
    func extractWordFromURL(url: URL) -> String {
        let fileNameWithExtension = url.lastPathComponent
        let fileNameWithoutExtension = (fileNameWithExtension as NSString).deletingPathExtension
        
        // Rimuovi numeri e caratteri speciali alla fine del nome del file
        let regexPattern = "[^A-Za-z]+$"
        if let range = fileNameWithoutExtension.range(of: regexPattern, options: .regularExpression, range: nil, locale: nil) {
            return String(fileNameWithoutExtension[..<range.lowerBound])
        } else {
            return fileNameWithoutExtension
        }
    }
//    AUTOMATIC SWITCH
//    func executeMapSwitching(){
//        switching = true
//        navMessage = "STOP"
//        switchingList.append(.now)
//        indexMapLoaded = indexToLoad!
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            switching = false
//            navMessage = "CONTINUE"
//            shouldSwitchMap = false
//        }
//    }
    
    var body: some View {
        if let l = list {
            
            
            VStack {
                
                Text("NAVIGATION").bold().font(.largeTitle)
                Text("Position in: \(extractedWord)").bold().font(.title3).foregroundColor(.green)
                
                if let _indexToLoad = indexToLoad {
                    Text("STATE: \(navMessage)").foregroundColor(navMessage == "STOP" ? .red : (navMessage == "CONTINUE" ? .green : .black)).bold()
                        .confirmationDialog("switch session", isPresented: $switchAlert) {
                            Button("switch to \(list![indexToLoad!].lastPathComponent)", role: .destructive) {
                                switching = true
                                navMessage = "STOP"
                                switchingList.append(.now)
                                indexMapLoaded = indexToLoad!
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2){
                                    switching = false
                                    navMessage = "CONTINUE"
                                }
                            }
                        }
                    
                    
                    //AUTOMATIC SWITCH
                    /*if shouldSwitchMap {
                     Text("SWITCHING...").foregroundColor(.red).bold()
                     .onAppear {
                     executeMapSwitching()
                     }
                     }*/
                }
                
                Text("switching: \(switching.description)")
                //Text("switchiTimes \(switchingList.count): \( switchingList.last?.ISO8601Format().description ?? "" )")
                
                Text(trackingState).onReceive(
                    NotificationCenter.default.publisher(for: .trackingState),
                    perform: {msg in if let m = msg.object as? ARCamera.TrackingState {
                        trackingState = trackingStateToString(m)
                        Model.shared.statusLocalSession = m
                    }}
                )
                
                
                
                if indexMapLoaded != -1 {
                    Text("Roto Matrix: \(rotoTrasl![indexMapLoaded].name)")
                    Text("Actual Map: \(l[indexMapLoaded].lastPathComponent)")
                }
                
                Picker("choose init map", selection: $indexMapLoaded) {
                    Text("Choose MAP")
                    
                    ForEach(Array(l.enumerated()), id: \.offset) { index, element in
                        Text(element.lastPathComponent).tag(index)
                    }
                }.onChange(of: indexMapLoaded, perform: { _ in
                    
                    Model.shared.updateRotos(Model.shared.actualRoto, rotoTrasl![indexMapLoaded] )
                    
                    if let map = worldTracking.getWorldMap(url: l[indexMapLoaded]){
                        
                        print("worldTracking.getWorldMap = \(String(describing: worldTracking.getWorldMap(url: l[indexMapLoaded])))")
                        
                        print(type(of: l[indexMapLoaded]))
                        
                        //calculate GLOBAL MAP NAME
                        extractedWord = extractWordFromURL(url: l[indexMapLoaded])
                        print(extractedWord)
                        
                        worldTracking.loadWorldMap(worldMap: map, l[indexMapLoaded].lastPathComponent)
                        print("load general from navigation borders true")
                        
                        globalView.loadgeneralMap(borders: true, name: extractedWord)
                        //globalView.addBoundingBox(bb: boundingBoxes[indexMapLoaded])
                        //globalView.drawOrigin(worldTracking.sceneView.scene.rootNode.worldPosition, UIColor(red: 0, green: 255, blue: 0, alpha: 1.0), 0.3)
                        singleView.loadRoomMaps(name: l[indexMapLoaded].lastPathComponent, borders: true)
                    }
                })
                
                
                /*HStack{
                 Button("<"){
                 Model.shared.updateRotos(
                 (indexMapLoaded == -1) ? nil : rotoTrasl![indexMapLoaded],
                 rotoTrasl![indexMapLoaded-1]
                 )
                 indexMapLoaded = indexMapLoaded-1
                 if let map = worldTracking.getWorldMap(url: l[indexMapLoaded]){
                 worldTracking.loadWorldMap(worldMap: map, l[indexMapLoaded].lastPathComponent)
                 globalView.loadgeneralMap()
                 //globalView.addBoundingBox(bb: boundingBoxes[indexMapLoaded])
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
                 //globalView.addBoundingBox(bb: boundingBoxes[indexMapLoaded])
                 globalView.drawOrigin(worldTracking.sceneView.scene.rootNode.worldPosition, UIColor(red: 0, green: 255, blue: 0, alpha: 1.0), 0.3)
                 singleView.loadRoomMaps(name: l[indexMapLoaded].lastPathComponent)
                 }
                 }.buttonStyle(.bordered).disabled(indexMapLoaded==l.count-1)
                 }*/
                //loadFeaturesPoints
                /*HStack {
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
                 
                 }*/
                
                
                //zoom
                
                
                //ARWorldMap ARSession + ortographic views
                VStack{
                    if indexMapLoaded != -1 {
                        
                        worldTracking.border(Color.white)
                            .cornerRadius(6)
                            .padding()
                            .shadow(color: Color.white, radius: 20)
                        
                        //ARWorldMap ARSession
                        HStack {
                            if indexMapLoaded != -1, let rotos = rotoTrasl, let map = worldTracking.getWorldMap(url: l[indexMapLoaded]) {
                                Button("+"){
                                    globalView.zoomIn()
                                    singleView.zoomIn()
                                }.buttonStyle(.bordered).bold().background(Color(red: 255/255, green: 235/255, blue: 205/255)).cornerRadius(6)
                                Button("-"){
                                    globalView.zoomOut()
                                    singleView.zoomOut()
                                }.buttonStyle(.bordered).bold().background(Color(red: 255/255, green: 235/255, blue: 205/255)).cornerRadius(6)
//                                Button("FT Global"){globalView.addBoundingBox(bb: boundingBoxesGlobal[indexMapLoaded], color: UIColor.magenta)}.buttonStyle(.bordered)
//                                Button("FT Local"){singleView.addBoundingBox(bb:  boundingBoxesLocal[indexMapLoaded], color: UIColor.magenta)}.buttonStyle(.bordered)
                            } else {
                                Text("No Map Available")
                            }
                        }
                        
                        globalView //ortographic view
                        
                        singleView //ortographic view
                            .onReceive(//position updater
                                NotificationCenter.default.publisher(for: .trackingPosition),
                                perform: {msg in if let m = msg.object as? simd_float4x4 {
                                    guard indexMapLoaded != -1 else {return}
                                    if let roto = rotoTrasl?[indexMapLoaded] {
                                        //NotificationCenter.default.post(name: .genericMessage, object: "update position with \(roto.name)")
                                        globalView.updatePosition(m, roto)
                                        singleView.updatePosition(m, nil)
                                        
                                        //BBdetection = ""
                                        var IndexIntersection: [Int] = []
                                        for (index, element) in boundingBoxesGlobal.enumerated() {
                                            
                                            let intersect = checkPointInsideBB(bb:element, point: Model.shared.lastKnowPositionInGlobalSpace!)
                                            if intersect {IndexIntersection.append(index)}
                                            //BBdetection += "index \(index) : \(intersect)\n"
                                        }
                                        
                                        //Number of BB
                                        BBdetection = "index intersected: \(IndexIntersection)"
                                        
                                        if switching {return}
                                        //Otherwise
                                        if IndexIntersection.count == 1 && IndexIntersection[0] != indexMapLoaded {
                                            indexToLoad = IndexIntersection[0]
                                            shouldSwitchMap = true
                                            switchAlert = true
                                        }
                                    }
                                }
                            }
                        )
                    }
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(red: 11/255, green: 121/255, blue: 157/255)).foregroundColor(.white)
        } else {
            Text("no maps availables")
        }
        
    }
}

#Preview {
    Navigation()
}
