//
//  RoomCaptureViewContainer.swift
//  autoMapping
//
//  Created by Stefano di Terlizzi on 11/07/23.
//  Upgraded by Michel Attilio Iodice on 24/10/24.
//

import SwiftUI
import RoomPlan
import ARKit
import PhotosUI

struct RoomCaptureViewContainer: UIViewRepresentable {
    
    typealias UIViewType = RoomCaptureView
    
    private let roomCaptureView: RoomCaptureView?
    
    static let arSession = ARSession()
    
    var sessionDelegate: SessionDelegate = SessionDelegate()
    
    private var isScanning: Bool = false
    
    private let configuration: RoomCaptureSession.Configuration = RoomCaptureSession.Configuration()
    
    let sceneView = SCNView()
    
    var imageSelection:PhotosPickerItem? = nil {
        didSet{
            
        }
    }
    
    
    init() {
        print("init roomCaptureView")
        if #available(iOS 17.0, *) {
            roomCaptureView = RoomCaptureView(frame: .zero, arSession: RoomCaptureViewContainer.arSession)
        } else {
            roomCaptureView = RoomCaptureView(frame: .zero)
        }
        roomCaptureView!.captureSession.delegate = sessionDelegate
        roomCaptureView!.delegate = sessionDelegate
        roomCaptureView!.captureSession.arSession.delegate = sessionDelegate
        sessionDelegate.setRoomCaptureView(self)
        
        if #available(iOS 17.0, *) {
            if let referenceImages = extractReferenceImages() {
                let config = ARWorldTrackingConfiguration()
                config.detectionImages = referenceImages
                config.sceneReconstruction = .mesh
                config.environmentTexturing = .automatic
                
                RoomCaptureViewContainer.arSession.run(config)
            }
        }
    }
    
    
    func makeUIView(context: Context) -> RoomCaptureView {
        roomCaptureView!.captureSession.run(configuration: configuration)
        
        sceneView.frame = roomCaptureView!.bounds
        sceneView.scene = SCNScene()
        sceneView.backgroundColor = .clear
        sceneView.isUserInteractionEnabled = false
        roomCaptureView!.addSubview(sceneView)
        return roomCaptureView!
    }
    
    func updateUIView(_ uiView: RoomCaptureView, context: Context) {}
    
    func stopCapture(pauseARSession: Bool, mapName: String) {
        
        SessionDelegate.save = !pauseARSession
        sessionDelegate.currentMapName = mapName
        
        if #available(iOS 17.0, *) {
            roomCaptureView!.captureSession.stop(pauseARSession: pauseARSession)
            /*roomCaptureView!.captureSession.arSession.getCurrentWorldMap(completionHandler:{worldMap, error in
             if let m = worldMap {saveARWorldMap(m)}
             })*/
        } else {
            roomCaptureView!.captureSession.stop()
        }
    }
    
    func loadImages(mapName: String, image: UIImage, name: String, author: String, description: String, width: String, height: String){
        let x_size: Float = Float(width) ?? 0.1
        let y_size: Float = Float(height) ?? 0.1
        let color = UIColor.generateUniqueRandomColor()
        CoreDataManager.shared.saveItem(names: name, authors: author, mapNames: mapName, x_sizes: x_size, y_sizes: y_size, comments: description, images: image, itemColors: color)
        NotificationCenter.default.post(
            name: Notification.Name("ArtWorks"),
            object: nil,
            userInfo: [ "artWorksName": name ])
        print("image:\(name), loaded")
    }
    
    func continueCapture() {
        roomCaptureView!.captureSession.run(configuration: configuration)
    }
    
    func redoCapture() {
        roomCaptureView!.captureSession.run(configuration: RoomCaptureSession.Configuration())
    }
    
    class SessionDelegate: UIViewController, RoomCaptureSessionDelegate, RoomCaptureViewDelegate, ARSessionDelegate {
        
        var currentMapName: String?
        
        var finalResults: CapturedRoom?
        
        var roomBuilder = RoomBuilder(options: [.beautifyObjects])
        
        private var featuresPoints: [UInt64] = []
        
        private var worldMapCounter = 0
        
        static var save = false
        
        var r: RoomCaptureViewContainer?
        
        var recognizedImageNodes: [SCNNode] = []
        
        func setRoomCaptureView(_ r: RoomCaptureViewContainer) {self.r = r}
        
        func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
            session.arSession.getCurrentWorldMap(completionHandler:{ worldMap, error in
                guard let worldMap = worldMap else {
                    print("Can't get current world map")
                    print(error!.localizedDescription)
                    return
                }
                self.worldMapCounter = self.worldMapCounter + 1
                NotificationCenter.default.post(name: .worldMapMessage, object: worldMap)
                NotificationCenter.default.post(name: .worlMapNewFeatures, object: worldMap.rawFeaturePoints.identifiers.difference(from: self.featuresPoints).count)
                NotificationCenter.default.post(name: .worldMapCounter, object: self.worldMapCounter)
                
            })
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            for anchor in anchors {
                guard let imageAnchor = anchor as? ARImageAnchor else { continue }
                handleImageRecognition(imageAnchor)
            }
        }
        func handleImageRecognition(_ imageAnchor: ARImageAnchor) {
            let imageAnchor = imageAnchor
            let referenceImage = imageAnchor.referenceImage
            let referenceImageName = referenceImage.name
            
            NotificationCenter.default.post(
                name: Notification.Name("ArtWorkFound"),
                object: nil,
                userInfo: [ "artWorkName": referenceImageName ?? "N/A" ])
            
            let transform = imageAnchor.transform
            
            let position = SCNVector3(
                x: transform.columns.3.x,
                y: transform.columns.3.y,
                z: transform.columns.3.z
            )
            let scaleX = simd_length(simd_float3(transform.columns.0.x, transform.columns.0.y, transform.columns.0.z))
            let scaleY = simd_length(simd_float3(transform.columns.1.x, transform.columns.1.y, transform.columns.1.z))
            let scaleZ = simd_length(simd_float3(transform.columns.2.x, transform.columns.2.y, transform.columns.2.z))
            let scale = SCNVector3(scaleX, scaleY, scaleZ)
            
            let rotationMatrix = transform.columns
            let sy = sqrt(rotationMatrix.0.x * rotationMatrix.0.x + rotationMatrix.1.x * rotationMatrix.1.x)
            let singular = sy < 1e-6
            let eulerX : Float
            let eulerY : Float
            let eulerZ : Float
            if !singular {
                eulerX = atan2(rotationMatrix.2.y, rotationMatrix.2.z)
                eulerY = atan2(-rotationMatrix.2.x, sy)
                eulerZ = atan2(rotationMatrix.1.x, rotationMatrix.0.x)
            } else {
                eulerX = atan2(-rotationMatrix.1.z, rotationMatrix.1.y)
                eulerY = atan2(-rotationMatrix.2.x, sy)
                eulerZ = 0
            }
            let eulerAngles = SCNVector3(eulerX, eulerY, eulerZ)
            
            let width = referenceImage.physicalSize.width
            let height = referenceImage.physicalSize.height
            let material = SCNMaterial()
            let itemImage = CoreDataManager.shared.fetchItemByName(name: referenceImageName!)
            var color = "red"
            if itemImage != nil { color = itemImage?.itemColor ?? "red"}
            let uiColor = UIColor(named: color)?.withAlphaComponent(0.2)
            material.diffuse.contents = uiColor
            material.isDoubleSided = true
            material.blendMode = .alpha
            
            let box = SCNBox(width: width, height: height, length: 0.02, chamferRadius: 0)
            box.materials = [material]
            let boxNode = SCNNode(geometry: box)
            let orientation = SCNMatrix4(imageAnchor.transform)
            
            boxNode.transform = orientation
            boxNode.position = position
            boxNode.scale = scale
            boxNode.eulerAngles = eulerAngles
            boxNode.name = referenceImageName

            DispatchQueue.main.async{
                self.r?.sceneView.scene?.rootNode.addChildNode(boxNode)
            }
            
            CoreDataManager.shared.setIsDetected(forName: referenceImageName!)
            print("Image:\(String(describing: referenceImageName)), found")
            
            
            func captureSession(_ session: RoomCaptureSession, didAdd room: CapturedRoom) {}
            
            func captureSession(_ session: RoomCaptureSession, didChange room: CapturedRoom) {}
            
            func captureSession(_ session: RoomCaptureSession, didRemove room: CapturedRoom) {}
            
            func captureSession(_ session: RoomCaptureSession, didProvide instruction: RoomCaptureSession.Instruction) {}
            
            func captureSession(_ session: RoomCaptureSession, didStartWith configuration: RoomCaptureSession.Configuration) {}
            
            func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: (Error)?) {
                //called when capture is stopped or stopped with an error
                print(SessionDelegate.save)
                if !SessionDelegate.save {return}
                
                if let error{
                    print("error in captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: (Error)?)")
                    print(error)
                }
                
                Task{
                    
                    let name = currentMapName ?? "_\(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))"
                    
                    
                    //            let formatter = DateFormatter()
                    //            formatter.dateFormat = "yyyMMdd'T'HHmmss"
                    //            name = "_\(formatter.string(from: Date()))"
                    let finalroom = try! await self.roomBuilder.capturedRoom(from: data)
                    
                    saveJSONMap(finalroom, name)
                    saveUSDZMap(finalroom, name)
                    
                    session.arSession.getCurrentWorldMap(completionHandler:{ [self] worldMap, error in
                        
                        if let m = worldMap {
                            
                            saveARWorldMap(m, name)
                            
                            if let n = worldMap?.rawFeaturePoints.identifiers.difference(from: featuresPoints) {
                                
                                featuresPoints.append(contentsOf: n)
                                
                            }
                            
                            SessionDelegate.save = false
                            
                        }
                    })
                }
            }
            
            // Decide to post-process and show the final results.
            func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
                print("captureView")
                print(CapturedRoomData.self)
                return true
            }
            
            // Access the final post-processed results.
            func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
                print("captureView 2")
                print(CapturedRoom.self)
                self.finalResults = processedResult
            }
            
            
            // MARK: - ARSessionDelegate
            //shows the current status of the world map.
            func session(_ session: ARSession, didUpdate frame: ARFrame) {
                
                switch frame.worldMappingStatus {
                    
                case .notAvailable:
                    NotificationCenter.default.post(name: .genericMessage, object: "Map Status: Not available")
                case .limited:
                    NotificationCenter.default.post(name: .genericMessage, object: "Map Status: Available but has Limited features")
                case .extending:
                    NotificationCenter.default.post(name: .genericMessage, object: "Map Status: Actively extending the map")
                case .mapped:
                    NotificationCenter.default.post(name: .genericMessage, object: "Map Status: Mapped the visible Area")
                @unknown default:
                    NotificationCenter.default.post(name: .genericMessage, object: "Map Status: @unknown default")
                    
                }
            }
        }
    }
}
var generatedColors = Set<String>()
extension UIColor {
    static func generateUniqueRandomColor() -> UIColor {
        var uniqueColor: UIColor
        var colorKey: String
        
        repeat {
            let red = CGFloat.random(in: 0...1)
            let green = CGFloat.random(in: 0...1)
            let blue = CGFloat.random(in: 0...1)
            
            uniqueColor = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
            colorKey = "\(red),\(green),\(blue)"
        } while generatedColors.contains(colorKey)
        
        generatedColors.insert(colorKey)
        return uniqueColor
    }
}
