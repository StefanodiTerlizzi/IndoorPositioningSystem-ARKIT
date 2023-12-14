//
//  Navigation.swift
//  autoMapping
//
//  Created by student on 01/12/23.
//

import SwiftUI
import simd
import ARKit

struct Navigation: View {
    
    let colors = [UIColor(red: 0, green: 255, blue: 0, alpha: 0.5), UIColor(red: 255, green: 255, blue: 0, alpha: 0.5)]
    
    var rotoTrasl: [DictToRototraslation]? = [
        DictToRototraslation(name: "Laboratorio", traslation: simd_float4x4([
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
    ]).inverse),
        DictToRototraslation(name: "Corridoio", traslation: simd_float4x4([
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
]).inverse)
    ]
    var boundingBoxesLocal: [[SCNNode]] = []
    var boundingBoxesGlobal: [[SCNNode]] = []
    
    //let list = listOfFilesURL(path: ["Maps"])
    let list: [URL]?
    var globalView = SCNViewContainer()
    var singleView = SCNViewContainer()
    var worldTracking = ARSCNViewContainer()
    
    @State var navMessage = ""

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
    
    init() {
        list = listOfFilesURL(path: ["Maps"])
        //rotoTrasl = createDictroto()
        
        if let _list = list {
            
            if rotoTrasl != nil {
                let names = _list.map{$0.lastPathComponent}
                rotoTrasl = rotoTrasl!.sorted {
                    guard let index1 = names.firstIndex(of: $0.name),
                          let index2 = names.firstIndex(of: $1.name) else {
                        return false
                    }
                    return index1 < index2
                }
            }
            
            //print(rotoTrasl?.map{$0.name})
            //print(_list.map{$0.lastPathComponent})
            
            
            for (index, element) in _list.enumerated() {
                if let _r = rotoTrasl, _r.contains(where: {$0.name == element.lastPathComponent}) {
                    print("call bb \(index)")
                    calculateBoundingBoxes(index: index, usdzMap: element)
                }
            }
            
            
            
        }
        
        print("checkAllRotos: \(checkAllRotos())")
    }
    
    mutating func calculateBoundingBoxes(index: Int, usdzMap: URL) {
        //print("BB \(index)")
        //print("calculate bounding box: \(usdzMap.lastPathComponent)")
        /*if let map = worldTracking.getWorldMap(url: list![index]){
            print(list![index])
            print(map)
            var min_X: Float?
            var max_X: Float?
            var min_Z: Float?
            var max_Z: Float?
            for (index, p) in map.rawFeaturePoints.points.enumerated() {
                min_X = (min_X==nil || p.x<min_X!) ? p.x : min_X
                max_X = (max_X==nil || p.x>max_X!) ? p.x : max_X
                
                min_Z = (min_Z==nil || p.x<min_Z!) ? p.z : min_Z
                max_Z = (max_Z==nil || p.x>max_Z!) ? p.z : max_Z
                
                //print(p)
                //if index%20 != 0 {continue}
                //let sphere = generateSingleSphereNode(color, 0.1)
                //sphere.name = "featurePoint"
                //sphere.simdWorldPosition = p
                //if let r = rototraslation {sphere.simdWorldTransform = simd_mul(sphere.simdWorldTransform, r.traslation)}
                //scnView.scene?.rootNode.addChildNode(sphere)
            }
            
            var min = Model.shared.origin.copy() as! SCNNode
            var max = Model.shared.origin.copy() as! SCNNode
            min.simdWorldPosition = simd_float3(min_X!, 2, min_Z!)
            max.simdWorldPosition = simd_float3(max_X!, 2, max_Z!)
            min = projectNode(min, rotoTrasl![index])
            max = projectNode(max, rotoTrasl![index])
            boundingBoxes.append(
                (
                    (min.simdWorldPosition.x, min.simdWorldPosition.z),
                    (max.simdWorldPosition.x, max.simdWorldPosition.z)
                )
            )
        }*/
        
        
        var scene = try! SCNScene(url: Model.shared.directoryURL.appending(path: "MapUsdz").appending(path: "\(usdzMap.lastPathComponent).usdz"))
        scene.rootNode.childNodes
            .forEach{
                $0.simdTransform = $0.simdWorldTransform
                scene.rootNode.addChildNode($0)
            }
        var a = SCNNode()
        var b = SCNNode()
        var c = SCNNode()
        var d = SCNNode()
        
        a.simdWorldPosition = simd_float3(scene.rootNode.boundingBox.0.x, 2, scene.rootNode.boundingBox.0.z)
        b.simdWorldPosition = simd_float3(scene.rootNode.boundingBox.0.x, 2, scene.rootNode.boundingBox.1.z)
        c.simdWorldPosition = simd_float3(scene.rootNode.boundingBox.1.x, 2, scene.rootNode.boundingBox.0.z)
        d.simdWorldPosition = simd_float3(scene.rootNode.boundingBox.1.x, 2, scene.rootNode.boundingBox.1.z)
        
        //var min = Model.shared.origin.copy() as! SCNNode
        //var max = Model.shared.origin.copy() as! SCNNode
        //min.simdWorldPosition = simd_float3(scene.rootNode.boundingBox.0)
        //max.simdWorldPosition = simd_float3(scene.rootNode.boundingBox.1)
        //min = projectNode(min, rotoTrasl![index])
        //max = projectNode(max, rotoTrasl![index])
        boundingBoxesLocal.append([a,b,d,c])
        
        var conv: [SCNNode] = []
        for e in [a,b,d,c] {
            conv.append(projectNode(e, rotoTrasl![index]))
        }
        boundingBoxesGlobal.append(conv)
        
        //print(scene.rootNode.boundingBox.0.x)
        //print(scene.rootNode.boundingBox.1)
    }
    
    func checkAllRotos() -> Bool {
        if let _r = rotoTrasl, let _l = list {
            let maps = Set(_l.map{$0.lastPathComponent})
            let rotos = Set(_r.map{$0.name})
            return maps.isSubset(of: rotos)
        }
        
        return false
    }
    
    var body: some View {
        if let l = list {
            VStack {
                /*HStack {
                    ForEach(boundingBoxes, id: \.0.0){ element in
                        let minX = element.0.0
                        let maxX = element.1.0
                        let minZ = element.0.1
                        let maxZ = element.1.1
                        Text("min x: \(minX), max x: \(maxX), min z: \(minZ), max z: \(maxZ)")
                    }
                }*/
                //Text("known position global: \(model.lastKnowPositionInGlobalSpace?.simdWorldPosition.x ?? -1) \(model.lastKnowPositionInGlobalSpace?.simdWorldPosition.z ?? -1)")
                
                if let _indexToLoad = indexToLoad {
                    Text("msg: \(navMessage)")
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
                }

                Text("switching: \(switching.description)")
                Text("switchiTimes \(switchingList.count): \( switchingList.last?.ISO8601Format().description ?? "" )")
                Text(trackingState).onReceive(
                    NotificationCenter.default.publisher(for: .trackingState),
                    perform: {msg in if let m = msg.object as? ARCamera.TrackingState {
                        trackingState=trackingStateToString(m)
                        Model.shared.statusLocalSession = m
                        //if Model.shared.statusLocalSession == .normal {globalView.drawOrigin(worldTracking.sceneView.scene.rootNode.worldPosition, UIColor(red: 50, green: 0, blue: 255, alpha: 1.0), 0.2, true)}
                    }}
                )
                
                /*Text("time loading: \(timeLoading)").onReceive(
                    NotificationCenter.default.publisher(for: .timeLoading),
                    perform: {msg in if let m = msg.object as? Double {timeLoading=m}}
                )*/
                
                //Text("BB detection: \(BBdetection)")
                
                if indexMapLoaded != -1 {
                    Text("roto: \(rotoTrasl![indexMapLoaded].name)")
                    Text("map: \(l[indexMapLoaded].lastPathComponent)")
                }
                
                //map
                Picker("choose init map", selection: $indexMapLoaded) {
                    Text("")
                    ForEach(Array(l.enumerated()), id: \.offset) { index, element in
                        Text(element.lastPathComponent).tag(index)
                    }
                }.onChange(of: indexMapLoaded, perform: { _ in
                    Model.shared.updateRotos(
                        Model.shared.actualRoto,
                        rotoTrasl![indexMapLoaded]
                    )
                    if let map = worldTracking.getWorldMap(url: l[indexMapLoaded]){
                        worldTracking.loadWorldMap(worldMap: map, l[indexMapLoaded].lastPathComponent)
                        print("load general from navigation borders true")
                        globalView.loadgeneralMap(borders: true)
                        //globalView.addBoundingBox(bb: boundingBoxes[indexMapLoaded])
                        //globalView.drawOrigin(worldTracking.sceneView.scene.rootNode.worldPosition, UIColor(red: 0, green: 255, blue: 0, alpha: 1.0), 0.3)
                        singleView.loadRoomMaps(name: l[indexMapLoaded].lastPathComponent, borders: true)
                    }
                }).disabled(!checkAllRotos())
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
                        Button("FT Global"){globalView.addBoundingBox(bb:  boundingBoxesGlobal[indexMapLoaded], color: UIColor.magenta)}.buttonStyle(.bordered)
                        Button("FT Local"){singleView.addBoundingBox(bb:  boundingBoxesLocal[indexMapLoaded], color: UIColor.magenta)}.buttonStyle(.bordered)
                    } else {
                        Text("no map")
                    }
                }
                
                //ARWorldMap ARSession + ortographic views
                VStack{
                    if indexMapLoaded != -1 {
                        worldTracking //ARWorldMap ARSession
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
                                            //let minX = (Model.shared.lastKnowPositionInGlobalSpace?.simdPosition.x)! >= element.0.0
                                            //let maxX = (Model.shared.lastKnowPositionInGlobalSpace?.simdPosition.x)! <= element.1.0
                                            //let minZ = (Model.shared.lastKnowPositionInGlobalSpace?.simdPosition.z)! >= element.0.1
                                            //let maxZ = (Model.shared.lastKnowPositionInGlobalSpace?.simdPosition.z)! <= element.1.1
                                            //BBdetection += "index \(index) : \(minX && maxX && minZ && maxZ)\n"
                                            let intersect = checkPointInsideBB(bb:element, point: Model.shared.lastKnowPositionInGlobalSpace!)
                                            if intersect {IndexIntersection.append(index)}
                                            //BBdetection += "index \(index) : \(intersect)\n"
                                        }
                                        BBdetection = "index intersected: \(IndexIntersection)"
                                        
                                        if switching {return}
                                        if IndexIntersection.count == 1 && IndexIntersection[0] != indexMapLoaded {
                                            indexToLoad = IndexIntersection[0]
                                            switchAlert = true
                                        }
                                        
                                        
                                    }
                                }}
                            )
                           
                    }
                }
            }
        } else {
            Text("no maps availables")
        }

    }
}

#Preview {
    Navigation()
}
