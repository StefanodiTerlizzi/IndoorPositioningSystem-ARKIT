//
//  RoomCaptureViewContainer.swift
//  autoMapping
//
//  Created by Stefano di Terlizzi on 11/07/23.
//

import SwiftUI
import RoomPlan
import ARKit

struct RoomCaptureViewContainer: UIViewRepresentable {
    
    typealias UIViewType = RoomCaptureView
    
    private let roomCaptureView: RoomCaptureView?
    
    static let arSession = ARSession()
    
    var sessionDelegate: SessionDelegate = SessionDelegate()
    
    private var isScanning: Bool = false
    
    private let configuration: RoomCaptureSession.Configuration = RoomCaptureSession.Configuration()
    
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
        print("makeUIView roomCaptureView")
        roomCaptureView!.captureSession.run(configuration: configuration)
        return roomCaptureView!
    }
    
    func updateUIView(_ uiView: RoomCaptureView, context: Context) {}
    
    func stopCapture(pauseARSession: Bool) {
        SessionDelegate.save = !pauseARSession
        if #available(iOS 17.0, *) {
            roomCaptureView!.captureSession.stop(pauseARSession: pauseARSession)
            /*roomCaptureView!.captureSession.arSession.getCurrentWorldMap(completionHandler:{worldMap, error in
                if let m = worldMap {saveARWorldMap(m)}
            })*/
        } else {
            roomCaptureView!.captureSession.stop()
        }
        
    }
    
    func continueCapture() {
        roomCaptureView!.captureSession.run(configuration: configuration)
    }
    
    func redoCapture() {
        roomCaptureView!.captureSession.run(configuration: RoomCaptureSession.Configuration())
    }
    
    /*
     func writeTempFile(books: [Book]) -> URL {
         let url = FileManager.default.temporaryDirectory
             .appendingPathComponent(UUID().uuidString)
             .appendingPathExtension("txt")
         let string = books
             .map({
                 "book '\($0.url.path)'"
             })
             .joined(separator: "\n")
         try? string.write(to: url, atomically: true, encoding: .utf8)
         return url
     }
     */
    
    
    func saveResult() -> Bool {
        Model.shared.finalResults = sessionDelegate.finalResults
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyMMdd'T'HHmmss"
        let dateString = "_\(formatter.string(from: Date()))"
        return true
//        var results: [Bool] = []
//        results.append(saveARWorldMap(dateString))
//        results.append(saveJSONMap(dateString))
//        results.append(saveUSDZMap(dateString))
//        print(results)
//        return results.reduce(true){ a, b in a&&b}
//        //WorldMap
//        roomCaptureView.captureSession.arSession.getCurrentWorldMap(completionHandler:{worldMap, error in
//            guard let worldMap = worldMap else {
//                print("Can't get current world map")
//                print(error!.localizedDescription)
//                return
//            }
//            
//            do {
//                let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
//                try data.write(to: Model.shared.directoryURL.appending(path: "Maps").appending(path: dateString), options: [.atomic])
//                //self.showAlert(message: "Map Saved")
//                NotificationCenter.default.post(name: .genericMessage, object: "map saved as \(Model.shared.directoryURL.appending(path: "Maps").appending(path: "_\(dateString)"))")
//                print("map saved in \(Model.shared.worldMapURL!)")
//            } catch {
//                fatalError("Can't save map: \(error.localizedDescription)")
//            }
//             
//        })
//        //JSON and usdz
//        do {
//            let jsonEncoder = JSONEncoder()
//            let jsonData = try jsonEncoder.encode(sessionDelegate.finalResults!)
//            try jsonData.write(to: Model.shared.jsonURL!)
//            try jsonData.write(to: Model.shared.directoryURL.appending(path: "JsonParametric").appending(path: "_\(dateString)"))
//            try sessionDelegate.finalResults!.export(to: Model.shared.usdzURL!, exportOptions: .parametric)
//            try sessionDelegate.finalResults!.export(to: Model.shared.directoryURL.appending(path: "MapUsdz").appending(path: "_\(dateString).usdz"), exportOptions: .parametric)
//            print("saved correctly")
//            NotificationCenter.default.post(name: .genericMessage, object: "json and USDZ saved as \(Model.shared.directoryURL.appending(path: "JsonParametric").appending(path: dateString)) and \(Model.shared.directoryURL.appending(path: "Usdz").appending(path: dateString))")
//            return true
//        } catch {
//            print("Error = \(error)")
//            return false
//        }
    }
}

/*struct RoomCaptureViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        RoomCaptureViewContainer()
    }
}*/

class SessionDelegate: UIViewController, RoomCaptureSessionDelegate, RoomCaptureViewDelegate, ARSessionDelegate {
    
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
                //self.setUpLabelsAndButtons(text: "Can't get current world map", canShowSaveButton: false)
                //self.showAlert(message: error!.localizedDescription)
                print("Can't get current world map")
                print(error!.localizedDescription)
                return
            }
            self.worldMapCounter = self.worldMapCounter + 1
            NotificationCenter.default.post(name: .worldMapMessage, object: worldMap)
            NotificationCenter.default.post(name: .worlMapNewFeatures, object: worldMap.rawFeaturePoints.identifiers.difference(from: self.featuresPoints).count)
            NotificationCenter.default.post(name: .worldMapCounter, object: self.worldMapCounter)
            
        })
        /*print("position from room")
        let transform = session.arSession.currentFrame?.camera.transform.columns.3
        print("x: \(String(describing: transform?.x)), y: \(String(describing: transform?.y)), z: \(String(describing: transform?.z))")
        position = transform
        print("room doors,opening,walls:")
        print(room.doors.count)
        print(room.openings.count)
        print(room.walls.count)

        print(room.objects.first?.category == CapturedRoom.Object.Category.table)*/
    }
    
    func captureSession(_ session: RoomCaptureSession, didAdd room: CapturedRoom) {
        
    }
    
    func captureSession(_ session: RoomCaptureSession, didChange room: CapturedRoom) {
        
    }
    
    func captureSession(_ session: RoomCaptureSession, didRemove room: CapturedRoom) {
        
    }
    
    func captureSession(_ session: RoomCaptureSession, didProvide instruction: RoomCaptureSession.Instruction) {
        
    }
    
    func captureSession(_ session: RoomCaptureSession, didStartWith configuration: RoomCaptureSession.Configuration) {
        
    }
    
    func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: (Error)?) {
        //called when capture is stopped or stopped with an error
        print(SessionDelegate.save)
        if !SessionDelegate.save {return}
        if let error{
            print("error in captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: (Error)?)")
            print(error)
        }
        Task{
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyMMdd'T'HHmmss"
            let name = "_\(formatter.string(from: Date()))"
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
                    //DispatchQueue.main.asyncAfter(deadline: .now()+2){self.r?.continueCapture()}
                    //print(SessionDelegate.save)
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
        /*switch frame.worldMappingStatus {
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
        }*/
    }
}
