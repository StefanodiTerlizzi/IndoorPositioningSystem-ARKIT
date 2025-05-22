//
//  ImageDetectionUtils.swift
//  autoMapping
//
//  Created by Michel Attilio Iodice on 22/05/25.
//

import Foundation
import ARKit
import RoomPlan
import SceneKit

func addNodesToUSDZ(room: CapturedRoom ,newNodes: [SCNNode]) -> SCNScene{
    let fileManager = FileManager.default
    let tempDir = fileManager.temporaryDirectory
    let usdzURL = tempDir.appendingPathComponent("tempRoom.usdz")
    var scene = SCNScene()
    do{
        if #available(iOS 17.0, *) {
            try room.export(to: usdzURL,exportOptions: [.parametric, .mesh])
        } else {
            try room.export(to: usdzURL,exportOptions: [.parametric])
        }
        
        scene = try SCNScene(url: usdzURL)
        for n in newNodes {
            scene.rootNode.addChildNode(n)
        }
    } catch {
        print("Error = \(error)")
    }
    return scene
}


@available(iOS 17.0, *)
func addNodeToMergedRooms(to room: CapturedStructure, for newNodes: [[String: Any]]) -> SCNScene {
    let fileManager = FileManager.default
    let tempDir = fileManager.temporaryDirectory
    let usdzURL = tempDir.appendingPathComponent("tempRoom.usdz")
    var scene = SCNScene()
    
    let walls: [CapturedStructure.Surface] = room.walls
    do{
        try room.export(to: usdzURL, exportOptions: [.mesh])
        scene = try SCNScene(url: usdzURL)
        for node in newNodes {
            let stringMatrixPosition = node["transformPosition"] as? [String] ?? []
            let matrixPosition: [Float] = stringMatrixPosition.compactMap {Float($0)}
            let transformPosition = simd_float3(matrixPosition[0], matrixPosition[1], matrixPosition[2])
            
            let stringMatrix = node["transform"] as? [String] ?? []
            let matrix: [Float] = stringMatrix.compactMap {Float($0)}
            let transform = simd_float4x4(
                simd_float4(matrix[0], matrix[1], matrix[2], matrix[3]),
                simd_float4(matrix[4], matrix[5], matrix[6], matrix[7]),
                simd_float4(matrix[8], matrix[9], matrix[10], matrix[11]),
                simd_float4(matrix[12], matrix[13], matrix[14], matrix[15])
            )
            
            let nodeColor: String = node["nodeColor"] as? String ?? "red"
            let imageName: String = node["imageName"] as? String ?? "Unknown"
            if let wallID:String = node["wallID"] as? String,
               let wall: CapturedStructure.Surface = findWall(from: walls, toId: wallID){
                print("found wall with id:\(wallID)")
                let wallPosition = SIMD3(wall.transform.columns.3.x,
                                              wall.transform.columns.3.y,
                                              wall.transform.columns.3.z)
                let nodeGlobalTrasnsformPosition = calcTransformPosition(from: wallPosition, with: transformPosition)
                
                let n = createNode(transform: transform,
                                   transformPosition: transformPosition,
                                   named: imageName,
                                   color: nodeColor)
                
                scene.rootNode.addChildNode(n)
                print("new nodes added!")
            }
        }
        
    } catch {
        print("Error = \(error)")
    }
    
    return scene
}

func createNode(transform matrix: simd_float4x4, transformPosition matrixPosition: simd_float3, named name: String, color colorName: String) -> SCNNode{
    
    let scaleX = simd_length(matrix.columns.0)
    let scaleY = simd_length(matrix.columns.1)
    let scaleZ = simd_length(matrix.columns.2)
    let uiColor = UIColor.color(from: colorName).withAlphaComponent(0.5)
    let material = SCNMaterial()
    material.diffuse.contents = uiColor
    material.isDoubleSided = true
    material.blendMode = .alpha
    
    let box = SCNBox(width: CGFloat(scaleX), height: CGFloat(scaleY), length: CGFloat(scaleZ), chamferRadius: 0)
    box.materials = [material]
    
    let boxNode = SCNNode(geometry: box)
    boxNode.simdTransform = matrix
    boxNode.name = name
    boxNode.simdWorldPosition.x = matrixPosition.x
    boxNode.simdWorldPosition.z = matrixPosition.z
    
    return boxNode
}

@available(iOS 17.0, *)
func findWall(from walls: [CapturedStructure.Surface], toId wallId: String ) -> CapturedStructure.Surface? {
    for wall in walls {
        if wall.identifier.uuidString.elementsEqual(wallId){
            return wall
        }
    }
    return nil
}


func generateJsonForNode(for nodes: [SCNNode], in room: CapturedRoom, to url: URL) throws {
    var resultArray: [[String: Any]] = []
    print("genereting json...")
    for n in nodes {
        let objectTransform = n.simdTransform
        
        if let wall = findWallForObject(in: room, objectTransform: objectTransform) {
            let nodePosition = n.simdWorldPosition
            let wallPosition = SIMD3(wall.transform.columns.3.x,
                                          wall.transform.columns.3.y,
                                          wall.transform.columns.3.z)
            let relative = relativeTransformPosition(of: nodePosition, to: wallPosition)
            var colorName = "red"
            if let color = n.geometry?.firstMaterial?.diffuse.contents as? UIColor {
                colorName = color.accessibilityName
            }
            let name = n.name ?? "Unknown"
            
            let matrix_0 = objectTransform.columns.0
            let matrix_1 = objectTransform.columns.1
            let matrix_2 = objectTransform.columns.2
            let matrix_3 = objectTransform.columns.3
            let transform: [String] = ["\(matrix_0.x)", "\(matrix_1.x)", "\(matrix_2.x)", "\(matrix_3.x)",
                                       "\(matrix_0.y)", "\(matrix_1.y)", "\(matrix_2.y)", "\(matrix_3.x)",
                                       "\(matrix_0.z)", "\(matrix_1.z)", "\(matrix_2.z)", "\(matrix_3.x)",
                                       "\(matrix_0.w)", "\(matrix_1.w)", "\(matrix_2.w)", "\(matrix_3.x)"]
            
            let transformPosition: [String] = ["\(relative.x)", "\(relative.y)", "\(relative.z)"]
            
            let dict: [String: Any] = [
                "wallID": wall.identifier.uuidString,
                "transform" : transform,
                "transformPosition": transformPosition,
                "nodeColor": colorName,
                "imageName": name
            ]
            
            resultArray.append(dict)
            print("new object added to json: \(url.description)")
        }
    }
    
    if FileManager.default.fileExists(atPath: url.path) {
        let existingData = try Data(contentsOf: url)
        if let existingArray = try JSONSerialization.jsonObject(with: existingData) as? [[String: Any]] {
            for e in existingArray {
                resultArray.append(e)
            }
        }
    }
    
    let data = try JSONSerialization.data(withJSONObject: resultArray, options: .prettyPrinted)
    try data.write(to: url)
    print("json write")
    
}


func wallEndpoints(from wall: CapturedRoom.Surface) -> (startPoint: SIMD3<Float>, endPoint: SIMD3<Float>) {
    let center = SIMD3<Float>(wall.transform.columns.3.x,
                              wall.transform.columns.3.y,
                              wall.transform.columns.3.z)
        
    let direction = SIMD3<Float>(wall.transform.columns.0.x,
                                 wall.transform.columns.0.y,
                                 wall.transform.columns.0.z)
        
    let halfLength = wall.dimensions.x / 2.0
        
    let startPoint = center - direction * halfLength
    let endPoint = center + direction * halfLength
        
    return (startPoint, endPoint)
}

func projectPointOnLineSegment(point: SIMD3<Float>, start: SIMD3<Float>, end: SIMD3<Float>) -> SIMD3<Float> {
    let lineVec = end - start
    let t = max(0, min(1, simd_dot(point - start, lineVec) / simd_length_squared(lineVec)))
    return start + t * lineVec
}

func findWallForObject(in room: CapturedRoom, objectTransform: simd_float4x4) -> CapturedRoom.Surface? {
    let objectPosition = SIMD3<Float>(objectTransform.columns.3.x,
                                      objectTransform.columns.3.y,
                                      objectTransform.columns.3.z)
        
    var closestWall: CapturedRoom.Surface? = nil
    var minDistance = Float.greatestFiniteMagnitude
        
    for wall in room.walls {
        let (startPoint, endPoint) = wallEndpoints(from: wall)
            
        let projectedPoint = projectPointOnLineSegment(point: objectPosition, start: startPoint, end: endPoint)
        let distance = simd_distance(objectPosition, projectedPoint)
            
        if distance < minDistance {
            minDistance = distance
            closestWall = wall
        }
    }
    return closestWall
}

func relativeTransformPosition(of objectPosition: simd_float3, to referencePosition: simd_float3) -> simd_float3 {
    // trasformazione relativa = inverse(reference) * object
    
    
    let diff_x = referencePosition.x - objectPosition.x
    let diff_y = referencePosition.y - objectPosition.y
    let diff_z = referencePosition.z - objectPosition.z
    
    return SIMD3(diff_x, diff_y, diff_z)
}

func calcTransformPosition(from object: simd_float3, with reference: simd_float3) -> simd_float3{
    
    let deltaX = reference.x
    let deltaY = reference.y
    let deltaZ = reference.z
    
    let newX = object.x - deltaX
    let newY = object.y - deltaY
    let newZ = object.z - deltaZ
    let newTransform = SIMD3(newX, newY, newZ)
    
    return newTransform
}


func loadNodeNames(from url: URL) throws -> [(name: String, color: String)] {
    let data = try Data(contentsOf: url)

    guard let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else {
        print("Invalid JSON structure")
        return []
    }

    let nodeInfo = jsonArray.compactMap { dict -> (String, String)? in
        guard let name = dict["imageName"] as? String,
              let color = dict["nodeColor"] as? String else {
            return nil
        }
        return (name, color)
    }

    return nodeInfo
}

func loadNodesJson(from url: URL) -> [[String: Any]]{
    
    do{
        let data = try Data(contentsOf: url)

        guard let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] else {
            print("Invalid JSON structure")
            return []
        }
        return jsonArray
    } catch {
        print("Invalid JSON structure")
        return []
    }
}

func verifyImageName(nameSearch: String) -> Bool {
    var verify: Bool = false
    let names: [String] = CoreDataManager.shared.fetchAllItemNames()
    for name in names {
        if name == nameSearch {
            verify = true
        }
    }
    return verify
}

func fetchDataItem() -> [Item]{
    let items: [Item] = CoreDataManager.shared.fetchAllItem()
    return items
}
func fetchDataItemFormap(mapNameRef: String) -> [Item]{
    let items: [Item] = CoreDataManager.shared.fetchItemByMapName(mapName: mapNameRef)
    return items
}

func extractReferenceImages() -> Set<ARReferenceImage>? {
    let items = fetchDataItem()
    var referenceImages = Set<ARReferenceImage>()
    
    for item in items {
        if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
            guard let cgImage = uiImage.cgImage else {
                print("Error in converision from UIImage to CGImage")
                continue
            }
            
            let imageSizeInMeters: CGFloat = CGFloat(item.x_size)
            let arImage = ARReferenceImage(cgImage, orientation: .up, physicalWidth: imageSizeInMeters)
            
            arImage.name = item.name ?? "Unknown Image"
            referenceImages.insert(arImage)
            
        }
    }
    return referenceImages.isEmpty ? nil : referenceImages
}

func extractReferenceImagesFormap(mapNameRef: String) -> Set<ARReferenceImage>? {
    let items = fetchDataItemFormap(mapNameRef: mapNameRef)
    var referenceImages = Set<ARReferenceImage>()
    
    for item in items {
        if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
            guard let cgImage = uiImage.cgImage else {
                print("Error in converision from UIImage to CGImage")
                continue
            }
            
            let imageSizeInMeters: CGFloat = CGFloat(item.x_size)
            let arImage = ARReferenceImage(cgImage, orientation: .up, physicalWidth: imageSizeInMeters)
            
            arImage.name = item.name ?? "Unknown Image"
            referenceImages.insert(arImage)
            
        }
    }
    return referenceImages.isEmpty ? nil : referenceImages
}

func extractArtWorksName(mapName:String) -> [Item] {
    var artWorks: [Item] = []
    let items: [Item] = CoreDataManager.shared.fetchItemByMapName(mapName: mapName.filter {!$0.isNumber})
    
    for item in items {
        if item.isDetected == true{
            artWorks.append(item)
        }
    }
    
    return artWorks
}

extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image {
            rendererContext in layer.render(in: rendererContext.cgContext)
        }
    }
}


var generatedColors = Set<String>()
extension UIColor {
    
    static func generateColor(random: Bool) -> UIColor {
        var uniqueColor: UIColor
        var colorKey: String

        let colorsSelection = [UIColor.red, UIColor.green, UIColor.blue, UIColor.yellow, UIColor.gray, UIColor.brown, UIColor.purple, UIColor.cyan, UIColor.magenta, UIColor.orange]
        repeat {
            let random = Int.random(in: 0..<colorsSelection.count)
            
            uniqueColor = colorsSelection[random]
            colorKey = uniqueColor.accessibilityName
            if generatedColors.count >= 10{
                generatedColors.remove(colorKey)
            }
        } while generatedColors.contains(colorKey)
        
        generatedColors.insert(colorKey)
        return uniqueColor
    }
    
    static func color(from string: String) -> UIColor{
        let s = string.lowercased()
        switch true {
            case s.contains("red"):
                return UIColor.red
            case s.contains("green"):
                return UIColor.green
            case s.contains("blue"):
                return UIColor.blue
            case s.contains("yellow"):
                return UIColor.yellow
            case s.contains("gray"):
                return UIColor.gray
            case s.contains("brown"):
                return UIColor.brown
            case s.contains("purple"):
                return UIColor.purple
            case s.contains("cyan"):
                return UIColor.cyan
            case s.contains("magenta"):
                return UIColor.magenta
            case s.contains("orange"):
                return UIColor.orange
            case s.contains("white"):
                return UIColor.white
            case s.contains("black"):
                return UIColor.black
            default:
                return UIColor.red
            }
    }
}
extension float4x4 {
    init(translation: SIMD3<Float>) {
        self = matrix_identity_float4x4
        columns.3 = SIMD4<Float>(translation.x, translation.y, translation.z, 1)
    }
}
