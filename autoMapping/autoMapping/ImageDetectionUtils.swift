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
            var notfound = true
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
            
            let stringMatrixWall = node["wallTransform"] as? [String] ?? []
            let matrixWall: [Float] = stringMatrixWall.compactMap {Float($0)}
            let wallTransform = simd_float4x4(
                simd_float4(matrixWall[0], matrixWall[1], matrixWall[2], matrixWall[3]),
                simd_float4(matrixWall[4], matrixWall[5], matrixWall[6], matrixWall[7]),
                simd_float4(matrixWall[8], matrixWall[9], matrixWall[10], matrixWall[11]),
                simd_float4(matrixWall[12], matrixWall[13], matrixWall[14], matrixWall[15])
            )
            
            let stringDimension = node["dimension"] as? [String] ?? []
            let dimensionMatrix: [Float] = stringDimension.compactMap {Float($0)}
            let dimension = SIMD3(dimensionMatrix[0],  dimensionMatrix[1], dimensionMatrix[2])
            
            let nodeColor: String = node["nodeColor"] as? String ?? "red"
            let imageName: String = node["imageName"] as? String ?? "Unknown"
            if let wallID:String = node["wallID"] as? String, let wall: CapturedStructure.Surface = findWall(from: walls, toId: wallID){
                print("found wall with id:\(wallID)")
                notfound = false
                let wallPosition = SIMD3(wall.transform.columns.3.x,
                                         wall.transform.columns.3.y,
                                         wall.transform.columns.3.z)
                let nodeGlobalTrasnsformPosition = calcTransformPosition(from: wallPosition, with: transformPosition)
                  
                let nodeTransform = computeTransform(originalTransformA: wall.transform, originalTransformB: transform)
                let n = createNode(transform: nodeTransform,
                                   dimension: dimension,
                                   transformPosition: nodeGlobalTrasnsformPosition,
                                   named: imageName,
                                   color: nodeColor)
                    
                scene.rootNode.addChildNode(n)
                print("new nodes added!")
                
            }
            if notfound{
                if let wallMatch: CapturedStructure.Surface = findMatchingWallByGeometry(originalTransform: wallTransform, room: room) {
                    print("found wall with geometry Match with id:\(wallMatch.identifier.uuidString)")
                    let wallPosition = SIMD3(wallMatch.transform.columns.3.x,
                                             wallMatch.transform.columns.3.y,
                                             wallMatch.transform.columns.3.z)
                    let nodeGlobalTrasnsformPosition = calcTransformPosition(from: wallPosition, with: transformPosition)
                    let nodeTransform = computeTransform(originalTransformA: wallMatch.transform, originalTransformB: transform)
                    
                    let n = createNode(transform: nodeTransform,
                                       dimension: dimension,
                                       transformPosition: nodeGlobalTrasnsformPosition,
                                       named: imageName,
                                       color: nodeColor)
                    
                    scene.rootNode.addChildNode(n)
                    print("new nodes added!")
                    
                }
            }
               
        }
        
    } catch {
        print("Error = \(error)")
    }
    
    return scene
}

func extractScale(from transform: simd_float4x4) -> SIMD3<Float> {
    let scaleX = simd_length(SIMD3(transform.columns.0.x,
                                   transform.columns.0.y,
                                   transform.columns.0.z))
    let scaleY = simd_length(SIMD3(transform.columns.1.x,
                                   transform.columns.1.y,
                                   transform.columns.1.z))
    let scaleZ = simd_length(SIMD3(transform.columns.2.x,
                                   transform.columns.2.y,
                                   transform.columns.2.z))
    
    return SIMD3<Float>(scaleX, scaleY, scaleZ)
}

func computeTransform(originalTransformA: simd_float4x4, originalTransformB targetTransform: simd_float4x4) -> simd_float4x4 {
    
    let rotationQuaternion = simd_quatf(originalTransformA)
    let pureRotationMatrix = matrix_float4x4(rotationQuaternion)
    
    let position = targetTransform.columns.3
    let scaleX = simd_length(targetTransform.columns.0)
    let scaleY = simd_length(targetTransform.columns.1)
    let scaleZ = simd_length(targetTransform.columns.2)
    var newTransform = pureRotationMatrix
    newTransform.columns.0 *= scaleX
    newTransform.columns.1 *= scaleY
    newTransform.columns.2 *= scaleZ
    newTransform.columns.3 = position

    
    return newTransform
}


func createNode(transform matrix: simd_float4x4, dimension: simd_float3, transformPosition matrixPosition: simd_float3, named name: String, color colorName: String) -> SCNNode{
    
    let uiColor = UIColor.color(from: colorName).withAlphaComponent(0.5)
    let material = SCNMaterial()
    material.diffuse.contents = uiColor
    material.isDoubleSided = true
    material.blendMode = .alpha
    
    
    
    let box = SCNBox(width: CGFloat(dimension.x), height: CGFloat(dimension.y), length: CGFloat(dimension.y), chamferRadius: 0)
    box.materials = [material]
    
    let boxNode = SCNNode(geometry: box)
    boxNode.name = name
    boxNode.simdTransform = matrix
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


func isSegmentContained(smallStart: SIMD2<Float>, smallEnd: SIMD2<Float>,
                        bigStart: SIMD2<Float>, bigEnd: SIMD2<Float>) -> Bool {
    let d = normalize(bigEnd - bigStart)
    let projectedSmallStart = dot(smallStart - bigStart, d)
    let projectedSmallEnd = dot(smallEnd - bigStart, d)
    return projectedSmallStart >= 0 && projectedSmallEnd <= length(bigEnd - bigStart)
}

/// Trova il muro fused che meglio corrisponde a quello originale
@available(iOS 17.0, *)
func findMatchingWallByGeometry(originalTransform: simd_float4x4,
                                room: CapturedStructure) -> CapturedRoom.Surface? {

    let (origStart, origEnd) = wallEndpoint(from: originalTransform)

    var bestMatch: Float? = nil
    var closestWall: CapturedRoom.Surface? = nil

    for wall in room.walls {
        let (mergedInit, mergedFinish) = wallEndpoints(from:wall)
        let mergedStart = SIMD2(mergedInit.x, mergedInit.z)
        let mergedEnd = SIMD2(mergedFinish.x, mergedFinish.z)


        // Controlla inclusione
        let included = isSegmentContained(smallStart: origStart, smallEnd: origEnd,
                                          bigStart: mergedStart, bigEnd: mergedEnd)
        if !included { continue }

        // Distanza minima tra segmenti (come fallback)
        let midOrig = (origStart + origEnd) / 2
        let midMerged = (mergedStart + mergedEnd) / 2
        let distance = length(midOrig - midMerged)

        if bestMatch == nil || distance < bestMatch! {
            bestMatch = distance
            closestWall = wall
        }
    }

    return closestWall
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
            var name = n.name ?? "Unknown"
            name = name.replacingOccurrences(of: "_", with: " ")
            
            let matrix_4 = wall.transform.columns.0
            let matrix_5 = wall.transform.columns.1
            let matrix_6 = wall.transform.columns.2
            let matrix_7 = wall.transform.columns.3
            let wallTransform: [String] = ["\(matrix_4.x)", "\(matrix_5.x)", "\(matrix_6.x)", "\(matrix_7.x)",
                                           "\(matrix_4.y)", "\(matrix_5.y)", "\(matrix_6.y)", "\(matrix_7.x)",
                                           "\(matrix_4.z)", "\(matrix_5.z)", "\(matrix_6.z)", "\(matrix_7.x)",
                                           "\(matrix_4.w)", "\(matrix_5.w)", "\(matrix_6.w)", "\(matrix_7.x)"]
            
            let matrix_0 = objectTransform.columns.0
            let matrix_1 = objectTransform.columns.1
            let matrix_2 = objectTransform.columns.2
            let matrix_3 = objectTransform.columns.3
            let transform: [String] = ["\(matrix_0.x)", "\(matrix_1.x)", "\(matrix_2.x)", "\(matrix_3.x)",
                                       "\(matrix_0.y)", "\(matrix_1.y)", "\(matrix_2.y)", "\(matrix_3.x)",
                                       "\(matrix_0.z)", "\(matrix_1.z)", "\(matrix_2.z)", "\(matrix_3.x)",
                                       "\(matrix_0.w)", "\(matrix_1.w)", "\(matrix_2.w)", "\(matrix_3.x)"]
            
            let transformPosition: [String] = ["\(relative.x)", "\(relative.y)", "\(relative.z)"]
            
            if let geometry = n.geometry as? SCNBox{
                let dimension:[String] = ["\(geometry.width)", "\(geometry.height)", "\(geometry.length)"]
                
                let dict: [String: Any] = [
                    "wallID": wall.identifier.uuidString,
                    "wallTransform": wallTransform,
                    "transform" : transform,
                    "transformPosition": transformPosition,
                    "dimension": dimension,
                    "nodeColor": colorName,
                    "imageName": name
                ]
                
                resultArray.append(dict)
                print("new object added to json: \(url.description)")
            }
            
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

func wallEndpoint(from wall: simd_float4x4) -> (startPoint: SIMD2<Float>, endPoint: SIMD2<Float>) {
    let center = SIMD2<Float>(wall.columns.3.x,
                              wall.columns.3.z)
        
    let direction = SIMD2<Float>(wall.columns.0.x,
                                 wall.columns.0.z)
    let length = simd_length(SIMD2<Float>(wall.columns.0.x, wall.columns.0.z))
    let halfLength = length / 2.0
        
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
    let items: [Item] = CoreDataManager.shared.fetchAllItem()
    for item in items {
        if item.name == nameSearch {
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
