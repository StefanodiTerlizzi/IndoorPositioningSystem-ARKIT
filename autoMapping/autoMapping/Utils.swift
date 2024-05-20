//
//  Utils.swift
//  autoMapping
//
//  Created by stefano on 2023/09/12.
//

import Foundation
import ARKit
import RoomPlan

//let jsonString = """
//{
//    "_20231017T144149": [
//        {
//            "local" : {"scale":[4.505766868591309, 3.0380802154541016, 0.00009999999747378752], "position": [ [0.9378055334091187, 0, 0.3471609652042389, 0], [0, 1, 0, 0], [-0.3471609652042389, 0, 0.9378055334091187, 0], [3.018605947494507, 0.18191944062709808, -4.782901763916016, 1] ]},
//            "global" : {"scale":[4.442831516265869, 2.9977312088012695, 0.00009999999747378752], "position": [ [0.9924401044845581, 0, 0.1227298229932785, 0], [0, 1, 0, 0], [-0.1227298229932785, 0, 0.9924400448799133, 0], [0.8831036686897278, 0.19110789895057678, -5.614522457122803, 1] ]}
//        }
//    ]
//}
//"""

/*
let testCases = [
    "A": [
        "P-z" : [
                [0.977, 0.004, -0.212, -1.031],
                [0.060, 0.951, 0.300, 0.388],
                [0.203, -0.306, 0.929, 1.619],
                [0.862, 0.101, -0.495, 1.0]
                ],
        "P+z" : [
                [-0.985, 0.005, 0.169, -1.054],
                [0.040, 0.977, 0.204, 0.490],
                [-0.164, 0.208, -0.963, 1.850],
                [-0.883, -00.060, 0.465, 1.0]
                ],
        "P-x" : [
                [-0.203, 0.177, -0.962, -0.752],
                [0.033, 0.984, 0.174, 0.394],
                [0.978, 0.003, -0.206, 1.758],
                [-0.501, 0.167, -0.848, 1.0]
                ],
        "P+x" : [
                [0.087, -0.210, 0.973, -1.392],
                [0.043, 0.977, 0.207, 0.373],
                [-0.995, 0.023, 0.095, 1.722],
                [0.397, -0.207, 0.893, 1.0]
                ],
    ],
    "B": [
        "P-z" : [
                [0.178, -0.012, 0.983, 1.621],
                [0.008, 0.999, 0.010, -0.212],
                [-0.983, 0.006, 0.178, 0.190],
                [0.479, -0.013, 0.877, 1.0]
                ],
        "P+z" : [
                [-0.130, 0.227, -0.964, 1.321],
                [0.015, 0.973, 0.227, 0.178],
                [0.991, 0.015, -0.130, 0.186],
                [-0.437, 0.211, -0.874, 1.0]
                ],
        "P-x" : [
                [0.985, 0.012, -0.171, 1.886],
                [0.000, 0.997, 0.076, -0.197],
                [0.171, -0.075, 0.982, 0.259],
                [0.880, 0.035, -0.472, 1.0]
                ],
        "P+x" : [
                [-0.986, -0.030, 0.161, 1.465],
                [0.003, 0.979, 0.202, 0.254],
                [-0.164, 0.200, -0.965, 0.418],
                [-0.883, -0.091, 0.458, 1.0]
                ],
    ],
    "C": [
        "P-z" : [
                [-0.982, -0.022, 0.183, -0.656],
                [0.018, 0.975, 0.219, 0.381],
                [-0.184, 0.218, -0.958, -2.929],
                [-0.874, -0.090, 0.476, 1.0]
                ],
        "P+z" : [
                [0.977, -0.012, 0.209, -0.533],
                [0.0552, 0.980, 0.187, 0.433],
                [0.203, -0.194, 0.959, -2.704],
                [0.863, 0.049, -0.501, 1.0]
                ],
        "P-x" : [
                [0.163, -0.163, 0.972, -0.635],
                [0.032, 0.986, 0.160, 0.501],
                [-0.986, 0.005, 0.166, -2.963],
                [0.466, -0.156, 0.870, 1.0]
                ],
        "P+x" : [
                [-0.176, 0.196, -0.964, -0.392],
                [0.022, 0.980, 0.195, 0.447],
                [0.984, 0.012, -0.177, -2.983],
                [-0.478, 0.182, -0.859, 1.0]
                ],
    ]
]

let testCases2 = [
    "A": [
        "P-z" : [
                [0.977, 0.004, -0.212, -1.031],
                [0.060, 0.951, 0.300, 0.388],
                [0.203, -0.306, 0.929, 1.619],
                [0.862, 0.101, -0.495, 1.0]
                ],
    ]
]

let originInGLobalSpace = [
    [0.973, 0.0, 0.229, -0.896],
    [0.0, 0.999, 0.0, 0.017],
    [-0.229, 0.0, 0.973, -0.212],
    [0.0, 0.0, 1.0, 1.0]
    ]
*/

func listOfFilesURL(path: [String]) -> [URL]? {
    if let document = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
        var defUrl = document
        for e in path {
            defUrl.append(path: e)
        }
        if let list = try? FileManager.default.contentsOfDirectory(at: defUrl, includingPropertiesForKeys: nil) {
            return list.sorted(by: {a,b in a.lastPathComponent<b.lastPathComponent})
        } else {
            print("error reading files at \(defUrl)")
        }
    }
    return nil
}

//func combineARWorldMaps(maps: [ARWorldMap]) -> ARWorldMap? {
//    var combined = maps[0]
//    for m in maps[1...] {
//        combined.anchors.append(contentsOf: m.anchors.difference(from: combined.anchors))
//        combined.rawFeaturePoints.
//            .append(contentsOf: m.rawFeaturePoints.difference(from: combined.rawFeaturePoints))
//    }
//    return nil
//}


extension Array where Element: Hashable {
    func difference(from other: [Element]) -> [Element] {
        let thisSet = Set(self)
        let otherSet = Set(other)
        return Array(thisSet.symmetricDifference(otherSet))
    }
}

func saveARWorldMap(_ worldMap: ARWorldMap, _ name: String) {
    do {
        let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
        try data.write(to: Model.shared.directoryURL.appending(path: "Maps").appending(path: name), options: [.atomic])
        NotificationCenter.default.post(name: .genericMessage, object: "saved AR: true")
    } catch {
        print("Can't save map: \(error.localizedDescription)")
        NotificationCenter.default.post(name: .genericMessage, object: "saved AR: false")
    }
}

func saveJSONMap(_ room: CapturedRoom, _ name: String) {
    do {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try jsonEncoder.encode(room)
        try jsonData.write(to: Model.shared.directoryURL.appending(path: "JsonParametric").appending(path: name))
        NotificationCenter.default.post(name: .genericMessage, object: "saved JSON: true")
    } catch {
        print("Error = \(error)")
        NotificationCenter.default.post(name: .genericMessage, object: "saved JSON: false")
    }
}

func saveUSDZMap(_ room: CapturedRoom, _ name: String) {
    do {
        if #available(iOS 17.0, *) {
            try room.export(
                to: Model.shared.directoryURL.appending(path: "MapUsdz").appending(path: "\(name).usdz"),
                metadataURL: Model.shared.directoryURL.appending(path: "PlistMetadata").appending(path: "\(name).plist"),
                exportOptions: [.parametric, .mesh]
            )
        } else {
            try room.export(
                to: Model.shared.directoryURL.appending(path: "MapUsdz").appending(path: "\(name).usdz"),
                exportOptions: [.parametric]
            )
        }
        NotificationCenter.default.post(name: .genericMessage, object: "saved USDZ: true")
    } catch {
        print("Error = \(error)")
        NotificationCenter.default.post(name: .genericMessage, object: "saved USDZ: false")
    }
}

/// Loads a captured room for the given URL.
private func loadCapturedRoom(from url: URL) throws -> CapturedRoom? {
    let jsonData = try? Data(contentsOf: url)
    guard let data = jsonData else { return nil }
    let capturedRoom = try? JSONDecoder().decode(CapturedRoom.self, from: data)
    return capturedRoom
}

/// Creates a 3D model from the given selected room URLS.  
@available(iOS 17.0, *)
func mergeSelectedRooms(mapName: String) {
    Task {
        /// An object that builds a single structure by merging multiple rooms.
        let structureBuilder = StructureBuilder(options: [.beautifyObjects])
        /// An object that holds a merged result.
        var finalResults: CapturedStructure?
        
        let exportFolderURL: URL = Model.shared.directoryURL.appending(path: "ExportCombined")
        let meshDestinationURL = exportFolderURL.appendingPathComponent("\(mapName).usdz")
        
        var capturedRoomArray: [CapturedRoom] = []
        for url in listOfFilesURL(path: ["JsonParametric"])! {
            if(url.lastPathComponent.hasPrefix("\(mapName)")){
                guard let room = try? loadCapturedRoom(from: url) else { continue }
                capturedRoomArray.append(room)
            }
        }
        
        do {
            finalResults = try await structureBuilder.capturedStructure(from: capturedRoomArray)
            if let f = finalResults {
                let roomDestinationURL = meshDestinationURL.deletingPathExtension().appendingPathExtension("json")
                try exportJson(from: f, to: roomDestinationURL)
                let metadataDestinationURL = meshDestinationURL.deletingPathExtension().appendingPathExtension("plist")
                try f.export(to: meshDestinationURL,
                                        metadataURL: metadataDestinationURL,
                                        exportOptions: [.mesh])
            }
            NotificationCenter.default.post(name: .genericMessage, object: "finish marging")
        } catch {
            NotificationCenter.default.post(name: .genericMessage, object: "Merging Error \(error.localizedDescription)")
            print("Merging Error: \(error.localizedDescription)")
            return
        }
    }
}

/// Exports the given captured structure in JSON format to a URL.
@available(iOS 17.0, *)
func exportJson(from capturedStructure: CapturedStructure, to url: URL) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(capturedStructure)
    try data.write(to: url)
}

func generateSphereNode(_ color: UIColor, _ radius: CGFloat) -> SCNNode {
    
    let houseNode = SCNNode() //3 Sphere
    let sphere = SCNSphere(radius: radius)
    //let sphere = SCNPyramid(width: radius, height: radius*2, length: radius)
    let sphereNode = SCNNode()
    sphereNode.geometry = sphere
    sphereNode.geometry?.firstMaterial?.diffuse.contents = color

    let sphere2 = SCNSphere(radius: radius)
    //let sphere = SCNPyramid(width: radius, height: radius*2, length: radius)
    let sphereNode2 = SCNNode()
    sphereNode2.geometry = sphere2
    var color2 = color
    sphereNode2.geometry?.firstMaterial?.diffuse.contents = color2.withAlphaComponent(color2.cgColor.alpha - 0.3)
    sphereNode2.position = SCNVector3(0, 0, -1)
    
    let sphere3 = SCNSphere(radius: radius)
    //let sphere = SCNPyramid(width: radius, height: radius*2, length: radius)
    let sphereNode3 = SCNNode()
    sphereNode3.geometry = sphere3
    var color3 = color
    sphereNode3.geometry?.firstMaterial?.diffuse.contents = color2.withAlphaComponent(color2.cgColor.alpha - 0.6)
    sphereNode3.position = SCNVector3(-0.5, 0, 0)
    
    
    houseNode.addChildNode(sphereNode)
    houseNode.addChildNode(sphereNode2)
    houseNode.addChildNode(sphereNode3)
    return houseNode
}

func generateConeNode(_ color: UIColor, _ radius: CGFloat) -> SCNNode {
    let sphere = SCNCone(topRadius: 0, bottomRadius: 0.5, height: 1)
    let sphereNode = SCNNode()
    sphereNode.geometry = sphere
    //sphereNode.eulerAngles.x = 1.5708
    //sphereNode.eulerAngles.z = 1.5708
    sphereNode.geometry?.firstMaterial?.diffuse.contents = color
    return sphereNode
}

extension UIColor {

    convenience init(red: UInt, green: UInt, blue: UInt, alpha: UInt = 0xFF) {
        self.init(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: CGFloat(alpha) / 255.0
        )
    }
}

func createSupportDirectories() {
    do {
        try FileManager.default.createDirectory(atPath: Model.shared.directoryURL.appending(path: "ExportCombined").path, withIntermediateDirectories: true, attributes: nil)
        try FileManager.default.createDirectory(atPath: Model.shared.directoryURL.appending(path: "JsonParametric").path, withIntermediateDirectories: true, attributes: nil)
        try FileManager.default.createDirectory(atPath: Model.shared.directoryURL.appending(path: "MapUsdz").path, withIntermediateDirectories: true, attributes: nil)
        try FileManager.default.createDirectory(atPath: Model.shared.directoryURL.appending(path: "Maps").path, withIntermediateDirectories: true, attributes: nil)
        try FileManager.default.createDirectory(atPath: Model.shared.directoryURL.appending(path: "JsonMaps").path, withIntermediateDirectories: true, attributes: nil)
        try FileManager.default.createDirectory(atPath: Model.shared.directoryURL.appending(path: "PlistMetadata").path, withIntermediateDirectories: true, attributes: nil)
    } catch {
        
    }
    
}

@available(iOS 17.0, *)
func getallRotoTraslationsAvailables() -> [DictToRototraslation]? {
    print("getAllRotos")
    var d: [DictToRototraslation] = []
    do {
        let generalFloor = try JSONDecoder().decode(CapturedRoom.self, from: try Data(contentsOf: Model.shared.directoryURL.appending(path: "ExportCombined").appending(path: "MergedRooms.json")))
        if let l = listOfFilesURL(path: ["JsonParametric"]) {
            for url in l {
                let room = try JSONDecoder().decode(CapturedRoom.self, from: try Data(contentsOf: url))
                let roomWalls = room.walls.filter({ w in w.parentIdentifier == nil})

                for local in roomWalls {
                    
                    if let global = generalFloor.walls.filter({$0.identifier == local.identifier}).first, global.parentIdentifier == nil {
                        //d.append(DictToRototraslation(name: "\(url.lastPathComponent)_\(local.identifier)", traslation: local.transform.inverse * global.transform))
                    }
                }
            }
            /*for i in 0..<d.count-2 {
                print("\(d[i].name) \(d[i+1].name) -> \(simd_equal(d[i].traslation, d[i+1].traslation))")
            }*/
        }
        return d.count != 0 ? d : nil
    } catch {
        print("error getAllRotos \(error)")
        return nil
    }
}

func calculateRotos()  -> [DictToRototraslation]? {
    print("calculateRotos")
    var d: [DictToRototraslation] = []
    
    guard let l = listOfFilesURL(path: ["Maps"]), l.count != 0 else {return nil}
    //print(l)
    
    let globalPlist = NSDictionary(contentsOfFile: Model.shared.directoryURL.appending(path: "ExportCombined").appending(path: "MergedRooms.plist").path())
    let globalScene = try? SCNScene(url: Model.shared.directoryURL.appending(path: "ExportCombined").appending(path: "MergedRooms.usdz"))
    guard let _globalPlist = globalPlist, let _globalScene = globalScene else {return nil}
    //print("global")
    for f in l {
        //print(f.lastPathComponent)
        let localPlist = NSDictionary(contentsOfFile: Model.shared.directoryURL.appending(path: "PlistMetadata").appending(path: "\(f.lastPathComponent).plist").path())
        let localScene = try? SCNScene(url: Model.shared.directoryURL.appending(path: "MapUsdz").appending(path: "\(f.lastPathComponent).usdz"))
        guard let _localPlist = localPlist, let _localScene = localScene else {continue}
        
        for kLocal in _localPlist.allKeys {
            //print(kLocal)
            do {
                let uuid = _localPlist.value(forKey: kLocal as! String) as! String
                let _kGlobal = _globalPlist.filter { (key: Any, value: Any) in value as! String == uuid}.first?.key
                guard let kGlobal = _kGlobal else {continue}
                //print("finding \(uuid) in \(f.lastPathComponent), global: \(kGlobal), local: \(kLocal)")
                let _gPosition = try _globalScene.rootNode.childNodes { n, _ in n.name == (kGlobal as! String)}.first?.simdWorldTransform
                let _lPosition = try _localScene.rootNode.childNodes { n, _ in n.name == (kLocal as! String)}.first?.simdWorldTransform
                guard let gPosition = _gPosition, let lPosition = _lPosition else {continue}
                //d.append(DictToRototraslation(name: "\(f.lastPathComponent)", traslation: simd_mul(gPosition, lPosition.inverse)))
                break
            } catch {
                print("error calculateRotos \(f) \(kLocal): \(error)")
            }
        }
        
        //print(d)
        /*for i in 0..<d.count-2 {
            print("\(d[i].name) \(d[i+1].name) -> \(simd_equal(d[i].traslation, d[i+1].traslation))")
        }*/
        //print(_globalPlist)
        
        
        //print(nsDictionary)
        //print(nsDictionary?.allKeys)
        
        
        //try! SCNScene(url: Model.shared.directoryURL.appending(path: "MapUsdz").appending(path: "\(name).usdz"))
        //let data = try! Data(contentsOf: Model.shared.directoryURL.appending(path: "PlistMetadata").appending(path: "\(f.lastPathComponent).plist"))
        //print(data)
        //guard let plist = try! PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as? [[String:Any]] else {return}
    }
    
    return d
}

func convertMaptoJSON() {
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first 
    else {
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
}

func trackingStateToString(_ state: ARCamera.TrackingState) -> String {
    switch state {
    case .normal:
        return "normal"
    case .notAvailable:
        return "not available"
    case .limited(.excessiveMotion):
        return "excessiveMotion"
    case .limited(.initializing):
        return "initializing"
    case .limited(.insufficientFeatures):
        return "insufficientFeatures"
    case .limited(.relocalizing):
        return "relocalizing"
    default:
        return ""
    }
}

func getMapsAvailables() -> [URL] {
    var maps: [URL] = []
    if let f = listOfFilesURL(path: ["MapUsdz"]) {
        maps.append(contentsOf: f)
    }
    if let f = listOfFilesURL(path: ["ExportCombined"])?.first {
        maps.append(f)
    }
    return maps
    
}

func projectNode(_ sphere: SCNNode, _ r: DictToRototraslation) -> SCNNode {
    sphere.simdWorldTransform.columns.3 = sphere.simdWorldTransform.columns.3 * r.traslation
    
    let r_Y = simd_float3x3([
        simd_float3(r.r_Y.columns.0.x, r.r_Y.columns.0.y, r.r_Y.columns.0.z),
        simd_float3(r.r_Y.columns.1.x, r.r_Y.columns.1.y, r.r_Y.columns.1.z),
        simd_float3(r.r_Y.columns.2.x, r.r_Y.columns.2.y, r.r_Y.columns.2.z),
    ])
    
    var rot = simd_float3x3([
        simd_float3(sphere.simdWorldTransform.columns.0.x, sphere.simdWorldTransform.columns.0.y, sphere.simdWorldTransform.columns.0.z),
        simd_float3(sphere.simdWorldTransform.columns.1.x, sphere.simdWorldTransform.columns.1.y, sphere.simdWorldTransform.columns.1.z),
        simd_float3(sphere.simdWorldTransform.columns.2.x, sphere.simdWorldTransform.columns.2.y, sphere.simdWorldTransform.columns.2.z),
    ])
    
    rot = r_Y * rot
    
    sphere.simdWorldTransform.columns.0 = simd_float4(
        rot.columns.0.x,
        rot.columns.0.y,
        rot.columns.0.z,
        sphere.simdWorldTransform.columns.0.z
    )
    sphere.simdWorldTransform.columns.1 = simd_float4(
        rot.columns.1.x,
        rot.columns.1.y,
        rot.columns.1.z,
        sphere.simdWorldTransform.columns.1.z
    )
    sphere.simdWorldTransform.columns.2 = simd_float4(
        rot.columns.2.x,
        rot.columns.2.y,
        rot.columns.2.z,
        sphere.simdWorldTransform.columns.2.z
    )
    
    return sphere
}

func PtoO_Pspace(T_P: simd_float4x4, T_O: simd_float4x4) -> (simd_float3, Float) {
    let R_P = simd_float3x3(
        columns: (
            simd_float3(T_P.columns.0.x, T_P.columns.0.y, T_P.columns.0.z),
            simd_float3(T_P.columns.1.x, T_P.columns.1.y, T_P.columns.1.z),
            simd_float3(T_P.columns.2.x, T_P.columns.2.y, T_P.columns.2.z)
        )
    )
    
    //print(R_P)
    //let t = simd_float3(T_O.columns.3.x, T_O.columns.3.y, T_O.columns.3.z) - simd_float3(T_P.columns.3.x, T_P.columns.3.y, T_P.columns.3.z)
    //print()
    //print(R_P.inverse)
    //print(R_P.inverse * t)
    
    let R_P_toO_Pspace =
        simd_mul(
            R_P.transpose,
            simd_float3x3(
                columns: (
                    simd_float3(T_O.columns.0.x, T_O.columns.0.y, T_O.columns.0.z),
                    simd_float3(T_O.columns.1.x, T_O.columns.1.y, T_O.columns.1.z),
                    simd_float3(T_O.columns.2.x, T_O.columns.2.y, T_O.columns.2.z)
                )
            )
        )
    
    
    
    return (
        simd_mul(
            R_P.inverse,
            (simd_float3(T_O.columns.3.x, T_O.columns.3.y, T_O.columns.3.z) - simd_float3(T_P.columns.3.x, T_P.columns.3.y, T_P.columns.3.z))
        ),
        GLKMathRadiansToDegrees(atan2(R_P_toO_Pspace.columns.2.x, R_P_toO_Pspace.columns.2.z))
    )
    
    
    
}

/*
 func print_PtoO_Pspace() {
 for item in testCases {
 print(item.key)
 for c in item.value {
 print(c.key)
 let TP = simd_float4x4(rows: [
 simd_float4(Float(c.value[0][0]), Float(c.value[0][1]), Float(c.value[0][2]), Float(c.value[0][3])),
 simd_float4(Float(c.value[1][0]), Float(c.value[1][1]), Float(c.value[1][2]), Float(c.value[1][3])),
 simd_float4(Float(c.value[2][0]), Float(c.value[2][1]), Float(c.value[2][2]), Float(c.value[2][3])),
 simd_float4(Float(c.value[3][0]), Float(c.value[3][1]), Float(c.value[3][2]), Float(c.value[3][3]))
 ])
 let TO = simd_float4x4(rows: [
 simd_float4(Float(originInGLobalSpace[0][0]), Float(originInGLobalSpace[0][1]), Float(originInGLobalSpace[0][2]), Float(originInGLobalSpace[0][3])),
 simd_float4(Float(originInGLobalSpace[1][0]), Float(originInGLobalSpace[1][1]), Float(originInGLobalSpace[1][2]), Float(originInGLobalSpace[1][3])),
 simd_float4(Float(originInGLobalSpace[2][0]), Float(originInGLobalSpace[2][1]), Float(originInGLobalSpace[2][2]), Float(originInGLobalSpace[2][3])),
 simd_float4(Float(originInGLobalSpace[3][0]), Float(originInGLobalSpace[3][1]), Float(originInGLobalSpace[3][2]), Float(originInGLobalSpace[3][3]))
 ])
 print(PtoO_Pspace(T_P: TP, T_O: TO))
 }
 }
 }
 */

func orderBySimilarity(node: SCNNode, listOfNodes: [SCNNode]) -> [SCNNode] {
    print(node.scale)
    var result: [(SCNNode, Float)] = []
    for n in listOfNodes {
        result.append((n, simd_fast_distance(n.simdScale, node.simdScale)))
    }
    return result.sorted(by: {a,b in a.1<b.1}).map{$0.0}
}

func fetchAPIConversionLocalGlobal(localName: String, nodesList: [(SCNNode, SCNNode)]) async throws -> (HTTPURLResponse?, [String: Any]) {
    //0 local, 1 global
    var jsonObj = [String: [Any]]()
    jsonObj[localName] = []
    
    for n in nodesList {
        
        await print(n.0.simdWorldTransform)
        await print(n.0.transform)
        await print(n.1.simdWorldTransform)
        await print(n.1.transform)
        
        var _local: [String: Any] = [:]
        
        _local["scale"] = await [n.0.scale.x, n.0.scale.y, n.0.scale.z]
        _local["eulerY"] = await n.0.eulerAngles.y
        _local["position"] = await [
            [n.0.simdWorldTransform.columns.0.x, n.0.simdWorldTransform.columns.0.y, n.0.simdWorldTransform.columns.0.z, n.0.simdWorldTransform.columns.0.w],
            [n.0.simdWorldTransform.columns.1.x, n.0.simdWorldTransform.columns.1.y, n.0.simdWorldTransform.columns.1.z, n.0.simdWorldTransform.columns.1.w],
            [n.0.simdWorldTransform.columns.2.x, n.0.simdWorldTransform.columns.2.y, n.0.simdWorldTransform.columns.2.z, n.0.simdWorldTransform.columns.2.w],
            [n.0.simdWorldTransform.columns.3.x, n.0.simdWorldTransform.columns.3.y, n.0.simdWorldTransform.columns.3.z, n.0.simdWorldTransform.columns.3.w]
        ]
        
        
        var _global: [String: Any] = [:]
        _global["scale"] = await [n.1.scale.x, n.1.scale.y, n.1.scale.z]
        _global["eulerY"] = await n.1.eulerAngles.y
        _global["position"] = await [
            [n.1.simdWorldTransform.columns.0.x, 
             n.1.simdWorldTransform.columns.0.y,
             n.1.simdWorldTransform.columns.0.z,
             n.1.simdWorldTransform.columns.0.w],
            [n.1.simdWorldTransform.columns.1.x, n.1.simdWorldTransform.columns.1.y, n.1.simdWorldTransform.columns.1.z, n.1.simdWorldTransform.columns.1.w],
            [n.1.simdWorldTransform.columns.2.x, n.1.simdWorldTransform.columns.2.y, n.1.simdWorldTransform.columns.2.z, n.1.simdWorldTransform.columns.2.w],
            [n.1.simdWorldTransform.columns.3.x, n.1.simdWorldTransform.columns.3.y, n.1.simdWorldTransform.columns.3.z, n.1.simdWorldTransform.columns.3.w]
        ]
        
        
        var e: [String: Any] = [:]
        e["local"] = _local
        e["global"] = _global
        jsonObj[localName]?.append(e)
    }
    
    //print(jsonObj)
    
    do {
        var data = try JSONSerialization.data(withJSONObject: jsonObj, options: .prettyPrinted)
        let s:String = String(data: data, encoding: .utf8)!
        //create the new url
        let url = URL(string: "https://develop.ewlab.di.unimi.it/musajapan/navigation/api/ransacalignment".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
        //print(s)
        //print(jsonString)
        //create a new urlRequest passing the url
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.httpBody = s.data(using: .utf8)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        //run the request and retrieve both the data and the response of the call
        let (bodyres, response) = try await URLSession.shared.data(for: request)
        //print(response)
        guard let httpResponse = response as? HTTPURLResponse else {return (nil, ["err":"error converting -> response as? HTTPURLResponse"])}
        let res = response as! HTTPURLResponse
        do {
            let _d = String(data: bodyres, encoding: .utf8)!.data(using: .utf8)!
            let resJson = try JSONSerialization.jsonObject(with: bodyres, options : .allowFragments) as! [String: Any]
            return (res, resJson)
        } catch {
            return (res, ["err": "error converting body response to JSON"])
        }
    } catch {
        return (nil, ["err": "error in sended data"])
    }
}

func generateSingleSphereNode(_ color: UIColor, _ radius: CGFloat) -> SCNNode {
    let sphere = SCNSphere(radius: radius)
    let sphereNode = SCNNode()
    sphereNode.geometry = sphere
    sphereNode.geometry?.firstMaterial?.diffuse.contents = color
    return sphereNode
}

func checkPointInsideBB(bb: [SCNNode], point: SCNNode) -> Bool {
    func pointIntersectEdge(
        p_x: Float,
        p_z: Float,
        e1_x: Float,
        e1_z: Float,
        e2_x: Float,
        e2_z: Float
    ) -> Bool {
        return (p_z < e1_z) != (p_z < e2_z) && (
            p_x < e1_x + ( ((p_z-e1_z) / (e2_z-e1_z)) * (e2_x-e1_x) )
        )
    }
    
    var inside = false
    var count = 0
    for i in 0..<bb.count {
        var v1 = bb[i]
        var v2 = bb[(i+1)%bb.count]
        if pointIntersectEdge(
            p_x: point.simdWorldPosition.x,
            p_z: point.simdWorldPosition.z,
            e1_x: v1.simdWorldPosition.x,
            e1_z: v1.simdWorldPosition.z,
            e2_x: v2.simdWorldPosition.x,
            e2_z: v2.simdWorldPosition.z
        ) {
            count += 1
        }
    }
    return count%2==1
}

func printMatrix(matrix: [[Double]], decimal: Int) -> String {
    let roundedMatrix = matrix.map { $0.map { String(format: "%.\(decimal)f", $0) } }
    let maxLength = roundedMatrix.flatMap { $0 }.max { $0.count < $1.count }?.count ?? 0
    return roundedMatrix.map { $0.map { String(repeating: " ", count: maxLength - $0.count) + $0 }.joined(separator: " ") }.joined(separator: "\n")
}

//Questa è la funzione che salva il calcolo della matrice di rototraslazione dell'API
func saveConversionGlobalLocal(_ conversions: [String: Any]) {
    var filteredDict = conversions.filter { $0.key.contains("TRANSFORMATION.LOCALTOGLOBAL") }
    filteredDict = Dictionary(uniqueKeysWithValues:filteredDict.map { key, value in
        let kMOD = String(key.split(separator: "_TRANSFORMATION.LOCALTOGLOBAL").first!)
        var vMOD = value as! [String: Any]
        vMOD = vMOD.filter{$0.key.contains("R_Y") || $0.key.contains("translation")}
        return (kMOD, vMOD)
    })
    
    updateJSONFile(filteredDict)
}
    
func updateJSONFile(_ dict: [String: Any]) {
    
    print("CALLING updateJSONFile ")
    let fileManager = FileManager.default
    let fileURL = Model.shared.conversionMatricesURL
    
    if fileManager.fileExists(atPath: fileURL.path()) {
        do {
            var jsonData = try Data(contentsOf: fileURL)
            var json = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: Any]
            for (key, value) in dict {
                json[key] = value
            }
            jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            try jsonData.write(to: fileURL)
        } catch {
            print(error.localizedDescription)
        }
    } 
    else {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
            try jsonData.write(to: fileURL)
        } catch {
            print(error.localizedDescription)
        }
    }
}

func createDictroto() -> [DictToRototraslation]? {
    if
        let data = try? Data(contentsOf: Model.shared.conversionMatricesURL),
        let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
        let jsonDict = jsonObject as? [String: [String: [[Double]]]]
    {
        
        var dictrotos: [DictToRototraslation] = []
        for (key, value) in jsonDict {
            if let translationMatrix = value["translation"],
               let r_YMatrix = value["R_Y"],
               translationMatrix.count == 4,
               r_YMatrix.count == 4 {
                
                let translation = simd_float4x4(rows: translationMatrix.map { simd_float4( $0.map{ Float($0) } ) })
                let r_Y = simd_float4x4(rows: r_YMatrix.map { simd_float4( $0.map{ Float($0) }) })
                
                dictrotos.append(DictToRototraslation(name: key, traslation: translation.transpose, r_Y: r_Y))
            }
        }
        return dictrotos

    } else {
        return nil
    }
    
}
