//
//  RoomCaptureViewContainer.swift
//  autoMapping
//
//  Created by Stefano di Terlizzi on 11/07/23.
//  Upgraded by Michel Attilio Iodice on 15/05/25.
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
    }
    
    func startImageDetection(mapNameSelected: String) {
        if #available(iOS 17.0, *) {
            if let referenceImages = extractReferenceImagesFormap(mapNameRef: mapNameSelected) {
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
        return roomCaptureView!
    }
    
    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
    }
    
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
        let x = width.replacingOccurrences(of: ",", with: ".")
        let y = height.replacingOccurrences(of: ",", with: ".")
        
        let x_size: Float = Float(x) ?? 0.1
        let y_size: Float = Float(y) ?? 0.1
        let color = UIColor.generateColor(random: true)
        CoreDataManager.shared.saveItem(names: name, authors: author, mapNames: mapName, x_sizes: x_size, y_sizes: y_size, comments: description, images: image, itemColors: color)
        NotificationCenter.default.post(
            name: Notification.Name("ArtWorks"),
            object: nil,
            userInfo: [ "artWorksName": name ])
        print("image:\(name), loaded")
    }
    
    func continueCapture(mapname:String) {
        if let sceneView = sessionDelegate.sceneViewOverlay {
            sceneView.removeFromSuperview()
            sessionDelegate.sceneViewOverlay = nil
            roomCaptureView?.isHidden = false
        }
        sessionDelegate.deleteNodes()
        startImageDetection(mapNameSelected: mapname)
        roomCaptureView!.captureSession.run(configuration: configuration)
    }
    
    func redoCapture(mapname:String) {
        if let sceneView = sessionDelegate.sceneViewOverlay {
            sceneView.removeFromSuperview()
            sessionDelegate.sceneViewOverlay = nil
            roomCaptureView?.isHidden = false
        }
        for n in sessionDelegate.recognizedImageNodes{
            var name = n.name ?? "Unknown"
            name = name.replacingOccurrences(of: "_", with: " ")
            name = name.replacingOccurrences(of: "__apos__", with: "'")
            CoreDataManager.shared.setIsDetected(forName: name, detected: false)
        }
        sessionDelegate.deleteNodes()
        SessionDelegate.save = false
        
        if #available(iOS 17.0, *) {
            roomCaptureView!.captureSession.stop(pauseARSession: false)
        } else {
            roomCaptureView!.captureSession.stop()
        }
        
        roomCaptureView!.captureSession.run(configuration: configuration)
        startImageDetection(mapNameSelected: mapname)
        
    }
    
    func showCustomScene(_ scene: SCNScene) {
        DispatchQueue.main.async {
            guard let roomCaptureView = self.roomCaptureView,
                  let superview = roomCaptureView.superview else { return }

            roomCaptureView.isHidden = true

            let scnView = SCNView(frame: roomCaptureView.frame)
            let cameraNode = SCNNode()
            cameraNode.camera = SCNCamera()
            scene.rootNode.addChildNode(cameraNode)
            
            centerCamera(on: scene, cameraNode: cameraNode)
            
            scnView.scene = scene
            scnView.pointOfView = cameraNode
            scnView.allowsCameraControl = true
            scnView.autoenablesDefaultLighting = true 
            
            self.sessionDelegate.sceneViewOverlay = scnView

            superview.addSubview(scnView)
            scnView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                scnView.topAnchor.constraint(equalTo: roomCaptureView.topAnchor),
                scnView.bottomAnchor.constraint(equalTo: roomCaptureView.bottomAnchor),
                scnView.leadingAnchor.constraint(equalTo: roomCaptureView.leadingAnchor),
                scnView.trailingAnchor.constraint(equalTo: roomCaptureView.trailingAnchor)
            ])
        }
    }
    
    class SessionDelegate: UIViewController, RoomCaptureSessionDelegate, RoomCaptureViewDelegate, ARSessionDelegate {
        
        var currentMapName: String?
        
        var finalResults: CapturedRoom?
        
        var sceneViewOverlay: SCNView?
        
        var roomBuilder = RoomBuilder(options: [.beautifyObjects])
        
        private var featuresPoints: [UInt64] = []
        
        private var worldMapCounter = 0
        
        static var save = false
        
        var r: RoomCaptureViewContainer?
        
        var recognizedImageNodes: [SCNNode] = []
        
        func setRoomCaptureView(_ r: RoomCaptureViewContainer) {self.r = r}
        
        func deleteNodes(){
            self.recognizedImageNodes=[]
            NotificationCenter.default.post(name: Notification.Name("ArtWorksDelete"), object: nil)
        }
        
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
            
            let scaleX = simd_length(transform.columns.0)
            let scaleY = simd_length(transform.columns.1)
            let scaleZ = simd_length(transform.columns.2)
            
            let itemImage = CoreDataManager.shared.fetchItemByName(name: referenceImageName!)
            var color = "#FF0000"
            if itemImage != nil { color = (itemImage?.itemColor)! }
            let uiColor = UIColor.fromHex(color)!
            let material = SCNMaterial()
            material.diffuse.contents = uiColor
            material.isDoubleSided = true
            material.blendMode = .alpha
            let width = Float(referenceImage.physicalSize.width) * scaleX
            let height = 0.3 * scaleZ
            let lenght = Float(referenceImage.physicalSize.height) * scaleY
            let box = SCNBox(width: CGFloat(width), height: CGFloat(height), length: CGFloat(lenght), chamferRadius: 0)
            box.materials = [material]
            
            let boxNode = SCNNode(geometry: box)
            
            boxNode.simdTransform = imageAnchor.transform
            boxNode.name = referenceImageName
            

            DispatchQueue.main.async{
                self.recognizedImageNodes.append(boxNode)
                CoreDataManager.shared.setIsDetected(forName: referenceImageName!)
                print("Image:\(String(describing: referenceImageName)), found")
            }
        }
        
        func isClose(_ a: Float, to b: Float, tolerance: Float = .pi / 4) -> Bool {
            return abs(a - b) < tolerance
        }
            
            func captureSession(_ session: RoomCaptureSession, didAdd room: CapturedRoom) {
            }
            
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
                    
                    saveJSONMap(finalroom, name, recognizedImageNodes)
                    let scene = saveUSDZMap(finalroom, name, recognizedImageNodes)
                    
                    session.arSession.getCurrentWorldMap(completionHandler:{ [self] worldMap, error in
                        
                        if let m = worldMap {
                            saveARWorldMap(m, name)
                            
                            if let n = worldMap?.rawFeaturePoints.identifiers.difference(from: featuresPoints) {
                                
                                featuresPoints.append(contentsOf: n)
                                
                            }
                            
                            SessionDelegate.save = false
                            
                        }
                    })
                    
                    if scene != nil {
                        self.r?.showCustomScene(scene!)
                    }
                    
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
    class LimitedCameraControlSCNView: SCNView, UIGestureRecognizerDelegate {
        
        override func didMoveToSuperview() {
            super.didMoveToSuperview()
            // Permetti solo rotazione e zoom (pinch), disabilita pan
            for recognizer in self.gestureRecognizers ?? [] {
                if let panGesture = recognizer as? UIPanGestureRecognizer {
                    panGesture.isEnabled = false
                }
            }
        }
    }

}
