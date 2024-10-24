//
//  RoomCaptureViewContainer.swift
//  autoMapping
//
//  Created by Stefano di Terlizzi on 11/07/23.
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
    
    
    func makeUIView(context: Context) -> RoomCaptureView {
        roomCaptureView!.captureSession.run(configuration: configuration)
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
    
    func loadImages(image: UIImage, name: String, description: String, width: String, height: String){
        
        let x_size: Float = Float(width)!
        let y_size: Float = Float(height)!
        
        CoreDataManager.shared.saveItem(name: name, x_size: x_size, y_size: y_size, comment: description, image: image)
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
