//
//  ARSCNViewContainer.swift
//  autoMapping
//
//  Created by Stefano di Terlizzi on 11/07/23.
//

import SwiftUI
import ARKit
import RoomPlan
import Foundation
import Accelerate

struct ARSCNViewContainer: UIViewRepresentable {
    
    typealias UIViewType = ARSCNView
    
    var sceneView = ARSCNView(frame: .zero)
    
    var configuration = ARWorldTrackingConfiguration()
    
    var delegate = ARSCNDelegate()
    
    func makeUIView(context: Context) -> ARSCNView {
        sceneView.delegate = delegate
        delegate.setSceneView(sceneView)
        //Set lighting to the view
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        return sceneView
    }
    
    func sceneFromURL(_ url: URL) {
        sceneView.allowsCameraControl = true
        sceneView.scene = try! SCNScene(url: Model.shared.usdzURL!)
        sceneView.session.run(configuration)
    }
    
    func planeDetectorRun() {
        configuration.planeDetection = [/*.horizontal,*/ .vertical]
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
    }
    
    func loadWorldMap(worldMap: ARWorldMap, _ filename: String) {
        
        let startDate = Date()
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        
        let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        var id = 0
        if let data = try? Data(contentsOf: Model.shared.directoryURL.appending(path: "JsonParametric").appending(path: filename)) {
            if let room = try? JSONDecoder().decode(CapturedRoom.self, from: data) {
                for e in room.doors {
                    worldMap.anchors.append(ARAnchor(name: "door\(id)", transform: e.transform))
                    id = id+1
                }
                for e in room.walls {
                    worldMap.anchors.append(ARAnchor(name: "wall\(id)", transform: e.transform))
                    id = id+1
                    
                }
            }
        }
        
        
        configuration.initialWorldMap = worldMap
        
        sceneView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        sceneView.session.run(configuration, options: options)
        
        if let p = Model.shared.lastKnowPositionInGlobalSpace, let a = Model.shared.actualRoto {
            
            //p.simdLocalRotate(by: simd_quatf(angle: GLKMathDegreesToRadians(90.0), axis: [0,0,1]))
            var originInGlobalSpace = Model.shared.origin.copy() as! SCNNode
            //originInGlobalSpace.simdLocalRotate(by: simd_quatf(angle: GLKMathDegreesToRadians(90.0), axis: [0,0,1]))
            originInGlobalSpace = projectNode(originInGlobalSpace, a)
            
            
            
            let Transl_Rot = PtoO_Pspace(T_P: p.simdWorldTransform, T_O: originInGlobalSpace.simdWorldTransform)
            let newOrig = Model.shared.origin.copy() as! SCNNode
            newOrig.simdPosition = Transl_Rot.0
            //newOrig.simdPosition.z = -2
            newOrig.simdLocalRotate(by: simd_quatf(angle: GLKMathDegreesToRadians(Transl_Rot.1), axis: [0,1,0]))
            sceneView.session.setWorldOrigin(relativeTransform: newOrig.simdWorldTransform)
            
            NotificationCenter.default.post(name: .genericMessage2, object: "translation: \(Transl_Rot.0)\nrotation: \(Transl_Rot.1)")
            
        }
        //if let p = Model.shared.actualPosition {sceneView.session.setWorldOrigin(relativeTransform: worldMap.)}
        print("timeLoading, object: \(fabs(startDate.timeIntervalSinceNow) * 1000))")
        NotificationCenter.default.post(name: .timeLoading, object: fabs(startDate.timeIntervalSinceNow) * 1000)
        //delegate.trState = nil
        NotificationCenter.default.post(name: .trackingState, object: "load new Map")
    }
    
    func getWorldMap(url: URL) -> ARWorldMap? {
        guard let mapData = try? Data(contentsOf: url), let worldMap = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: mapData) else {
            return nil
        }
        return worldMap
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
}

class ARSCNDelegate: NSObject, ARSCNViewDelegate {
    
    private var sceneView: ARSCNView?
    var trState: ARCamera.TrackingState?
    
    override init(){
        super.init()
    }
    
    func setSceneView(_ scnV: ARSCNView) {
        sceneView = scnV
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        /*guard !(anchor is ARPlaneAnchor) else { return }
        var color = UIColor(red: 255, green: 255, blue: 255, alpha: 1.0)
        if let n = anchor.name, n.hasPrefix("door") {color = UIColor(red: 255, green: 0, blue: 0, alpha: 1.0)}
        if let n = anchor.name, n.hasPrefix("wall") {color = UIColor(red: 0, green: 255, blue: 0, alpha: 1.0)}
        
        let sphereNode = generateSphereNode(color, 0.05)
        DispatchQueue.main.async {
            node.addChildNode(sphereNode)
        }*/
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        if let camera = self.sceneView?.session.currentFrame?.camera {
            DispatchQueue.main.async {NotificationCenter.default.post(name: .trackingPosition, object:
                                                                        camera.transform)}
        }
        
        if trState == self.sceneView?.session.currentFrame?.camera.trackingState{return}
        
        trState = self.sceneView?.session.currentFrame?.camera.trackingState
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .trackingState, object: self.trState)
        }
    }
    
    
}


struct ARSCNViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        ARSCNViewContainer()
    }
}
