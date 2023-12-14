//
//  ScanningEnvironment.swift
//  autoMapping
//
//  Created by student on 06/12/23.
//

import SwiftUI
import ARKit

struct ScanningEnvironment: View {
    
    @State private var messagesFromWorldMap: String = ""
    @State private var worlMapNewFeatures: Int = 0
    @State private var worldMapCounter: Int = 0
    @State var isScanningRoom = true
    var roomcaptureView = RoomCaptureViewContainer()

    
    var body: some View {
        VStack {
            Text("worldMapCounter: \(worldMapCounter)")
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name.worldMapCounter), perform: {coutner in
                    if let counter = coutner.object as? Int {worldMapCounter = counter}
                })
            Text(messagesFromWorldMap)
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name.worldMapMessage), perform: {message in
                    if let worldMap = message.object as? ARWorldMap {
                        messagesFromWorldMap = """
                        mapDimension in m2: \(worldMap.extent.x * worldMap.extent.z)\n
                        anchors: \(worldMap.anchors.count)\n
                        features:\(worldMap.rawFeaturePoints.identifiers.count)
                        """
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
    }
}

#Preview {
    ScanningEnvironment()
}
