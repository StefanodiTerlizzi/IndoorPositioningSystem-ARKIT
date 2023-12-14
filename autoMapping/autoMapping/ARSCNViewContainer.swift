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
        
        
        //let wTrans = sceneView.scene.rootNode.worldTransform
        
        /*if (delegate.trState == .normal) {
            CMMotionDetector.shared.startDeviceMotionUpdates(to: OperationQueue()){ dataMotion, error in
                guard let dataMotion = dataMotion else { return }
                NotificationCenter.default.post(name: .trackingPositionFromMotionManager, object: dataMotion)
                /*DispatchQueue.main.async {
                    LoggingSystem.pushLocal(eventLog: ["event":"Inertial sensor data","museum": self.museum.name, "timestamp":Date().timeIntervalSince1970, "artWork": self.lastRecognizedWork?.itemid ?? -1, "magnetic_field_x": dataMotion.magneticField.field.x, "magnetic_field_y": dataMotion.magneticField.field.y, "magnetic_field_z": dataMotion.magneticField.field.z, "user_acceleration_x": dataMotion.userAcceleration.x, "user_acceleration_y": dataMotion.userAcceleration.y, "user_acceleration_z": dataMotion.userAcceleration.z, "rotation_rate_x": dataMotion.rotationRate.x, "rotation_rate_y": dataMotion.rotationRate.y, "rotation_rate_z": dataMotion.rotationRate.z], verbose: false)
                }*/
            }
        }*/
        
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
        /*if Model.shared.previousRoto != nil {
            let posInNewSession = nil
            sceneView.session.setWorldOrigin(relativeTransform: simd_float4x4)
        }*/
        /*for a in worldMap.anchors {
            let sphereNode = SCNNode(geometry: SCNSphere(radius: 0.1))
            sphereNode.position = SCNVector3(a.transform.columns.3.x, a.transform.columns.3.y, a.transform.columns.3.z)
            sceneView.scene.rootNode.addChildNode(sphereNode)
        }*/
        sceneView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        sceneView.session.run(configuration, options: options)
        //print("origin on loading scene")
        //print(sceneView.scene.rootNode.simdWorldTransform)
        //print(sceneView.scene.rootNode.simdWorldPosition)
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
            
            
            
            //originInGlobalSpace.simdLocalRotate(by: simd_quatf(angle: GLKMathDegreesToRadians(90.0), axis: [0,0,1]))
            
            
            //let newOrig = p.convertPosition(originInGlobalSpace.worldPosition, from: nil)
            //let newOrig = Model.shared.origin.convertPosition(originInGlobalSpace.worldPosition, to: p)
            //let newOrig = p.simdConvertPosition(originInGlobalSpace.simdWorldPosition, from: nil)
            //let newOrig = p.simdConvertTransform(originInGlobalSpace.simdWorldTransform, from: nil)
            
            //p.simdLocalRotate(by: simd_quatf(angle: GLKMathDegreesToRadians(-90.0), axis: [0,0,1]))
            
            //let diffRadiansX = p.eulerAngles.x - originInGlobalSpace.eulerAngles.x
            //let diffRadiansY = p.eulerAngles.y - originInGlobalSpace.eulerAngles.y
            //let diffRadiansZ = p.eulerAngles.z - originInGlobalSpace.eulerAngles.z
            
            
            //sceneView.session.setWorldOrigin(relativeTransform: (simd_float4x4([1.0,0,0,0],[0,1.0,0,0],[0,0,1.0,0],[0,0,0,1.0]) - p) * a)
            /*
            var O = SCNNode()
            O.simdWorldTransform = simd_float4x4([1.0,0,0,0],[0,1.0,0,0],[0,0,1.0,0],[0,0,0,1.0])
            O = projectNode(O, a)
            
            let q = p.orientation
            let heading = atan2f( (2 * q.y * q.w) - (2 * q.x * q.z), 1 - (2 * pow(q.y,2)) - (2 * pow(q.z,2)) )
            let attitude = asinf( (2 * q.x * q.y) + (2 * q.z * q.w) )
            let bank = atan2f( (2 * q.x * q.w) - (2 * q.y * q.z), 1 - (2 * pow(q.x,2)) - (2 * pow(q.z,2)) )

            let t1 = "posizione attuale X: \(attitude * (180.0 / .pi)) Y: \(heading * (180.0 / .pi)) Z: \(bank * (180.0 / .pi))"
            
            let q2 = O.orientation
            let heading2 = atan2f( (2 * q2.y * q2.w) - (2 * q2.x * q2.z), 1 - (2 * pow(q2.y,2)) - (2 * pow(q2.z,2)) )
            let attitude2 = asinf( (2 * q2.x * q2.y) + (2 * q2.z * q2.w) )
            let bank2 = atan2f( (2 * q2.x * q2.w) - (2 * q2.y * q2.z), 1 - (2 * pow(q2.x,2)) - (2 * pow(q2.z,2)) )

            let t2 = "nuova origine X: \(attitude2 * (180.0 / .pi)) Y: \(heading2 * (180.0 / .pi)) Z: \(bank2 * (180.0 / .pi))"
            
            
            //p.rotation.w = 0
            let r1 = "known point rotation: \(p.rotation)"
            let r2 = "origin rotation: \(O.rotation)"

            
            var origin = sceneView.scene.rootNode
            NotificationCenter.default.post(name: .genericMessage2, object: "\(r1)\n\(r2)\nknowpointY:\(p.rotation.y)\norigin\(origin.simdWorldTransform)")
            print("origin")
            print(origin.simdWorldTransform)
            origin.rotation.w = O.rotation.w - p.rotation.w
            origin.rotation.y = O.rotation.y - p.rotation.y
             */
            
            //GlobalSpace
            
            //let rot = GLKQuaternionNormalize(GLKQuaternion(q: (0, p.rotation.y, 0, p.rotation.w)))
            //p.rotation = SCNVector4(rot.x,rot.y,rot.z,rot.s)
                        
            //let rotO = GLKQuaternionNormalize(GLKQuaternion(q: (0, O.rotation.y, 0, O.rotation.w)))
            //O.rotation = SCNVector4(rotO.x,rotO.y,rotO.z,rotO.s)
            
/*            NotificationCenter.default.post(name: .genericMessage2, object: """
                p.r \(p.eulerAngles)\n
                O.r \(O.eulerAngles)\n
                degree rotation origin \(GLKMathRadiansToDegrees(O.rotation.y))\n
                radians rotation origin \(O.rotation.y)\n
                degree rotation P \(GLKMathRadiansToDegrees(p.rotation.y))\n
                radians rotation P \(p.rotation.y)\n
                diff \(GLKMathRadiansToDegrees(O.rotation.y) - GLKMathRadiansToDegrees(p.rotation.y))
            """)
*/
            //let inversion = DictToRototraslation(name: "inv", traslation: Model.shared.actualRoto!.traslation.inverse, r_Y: Model.shared.actualRoto!.r_Y.inverse)
            //var sphere2 = generateSphereNode(UIColor(red: 255, green: 0, blue: 0, alpha: 1.0), 0.2)
            //sphere2.simdWorldTransform = p.simdWorldTransform
            //sphere2.simdWorldTransform = projectNode(sphere2, inversion).simdWorldTransform
            
            
            
            //var mex = sphere2.simdWorldPosition
            
            //let diffRadiansY = sphere2.eulerAngles.y
            //let diffRadiansX = sphere2.eulerAngles.x
            //let diffRadiansZ = sphere2.eulerAngles.z
            
            //let distance = sqrt(pow(sphere2.simdWorldPosition.x, 2) + pow(sphere2.simdWorldPosition.z, 2))
            //let newx = distance * cos(GLKMathRadiansToDegrees(diffRadiansX))
            //let newy = distance * sin(GLKMathRadiansToDegrees(diffRadiansX))
            
            
            //sphere2.eulerAngles.y = -diffRadians
            
            //var newOrigin = Model.shared.origin.copy() as! SCNNode
            
            //newOrigin.simdWorldTransform.columns.3 = newOrig.columns.3
            //simd_float3(x: newOrig.columns.3.x, y: newOrig.columns.3.y, z: newOrig.columns.3.z)
            //newOrigin.simdLocalRotate(by: simd_quatf(angle: diffRadiansX, axis: [0,1,0]))
            
            /*func rotatePoint(node: SCNNode, angle: Float) -> SCNNode {
                let rotatedX = node.simdWorldPosition.y * cos(angle) - node.simdWorldPosition.z * sin(angle)
                let rotatedZ = node.simdWorldPosition.y * sin(angle) + node.simdWorldPosition.z * cos(angle)
                node.simdWorldPosition.x = rotatedX
                node.simdWorldPosition.z = rotatedZ
                return node
            }*/
            
            
            
            /*
             diff Y \(GLKMathRadiansToDegrees(diffRadiansY))
             diff X \(GLKMathRadiansToDegrees(diffRadiansX))
             diff Z \(GLKMathRadiansToDegrees(diffRadiansZ))
            */
            
            //let originInGlobalSpace = projectNode(Model.shared.origin, a)
            /*NotificationCenter.default.post(name: .genericMessage2, object: """
                diff degree X Y Z \(GLKMathRadiansToDegrees(diffRadiansX)) \(GLKMathRadiansToDegrees(diffRadiansY)) \(GLKMathRadiansToDegrees(diffRadiansZ))
                newOr \(simd_precise_distance(simd_float4(0,0,0,1), newOrig.columns.3))
                distance \(simd_precise_distance(p.simdWorldPosition, originInGlobalSpace.simdWorldPosition))
            """)*/
            /*
             newOrigini \(newOrigin.simdWorldTransform.columns.3)
             Og \(originInGlobalSpace.simdWorldTransform.columns.3)
             Pg \(p.simdWorldTransform.columns.3)
             */
            
            //let conv = p.simdConvertPosition(originInGlobalSpace.simdWorldPosition, from: nil)
            //newOrigin.eulerAngles.y = -diffRadiansY
            //newOrigin.simdWorldPosition.x = conv.y
            //newOrigin.simdWorldPosition.z = conv.x
            
            /*let RY = simd_float4x4(
                simd_float4(cos(GLKMathRadiansToDegrees(diffRadiansY)), 0, sin(GLKMathRadiansToDegrees(diffRadiansY)), 0),
                simd_float4(0,1,0,0),
                simd_float4(-sin(GLKMathRadiansToDegrees(diffRadiansY)), 0, cos(GLKMathRadiansToDegrees(diffRadiansY)), 0),
                simd_float4(0,0,0,1)
            )*/
            
            /*let alpha = simd_float4x4(
                simd_float4(1,0,0, p.simdWorldTransform.columns.3.x),
                simd_float4(0,1,0, p.simdWorldTransform.columns.3.y),
                simd_float4(0,0,1, p.simdWorldTransform.columns.3.z),
                simd_float4(0,0,0,1)
            ).inverse*/
            /*
            NotificationCenter.default.post(name: .genericMessage2, object: """
                pointInGlobalSpace \(p.simdWorldTransform)
                originInglobalSpace \(originInGlobalSpace.simdWorldTransform)
            """)*/
            
            /*NotificationCenter.default.post(name: .genericMessage2, object: """
                oldposition \(mex)
                newPosition after rotation - \(rotatePoint(node: sphere2, angle: -GLKMathRadiansToDegrees(diffRadiansX)).simdWorldPosition)
                newPosition after rotation \(rotatePoint(node: sphere2, angle: GLKMathRadiansToDegrees(diffRadiansX)).simdWorldPosition)
                
            """)*/
            
            
            /*
             \(newOrigin.simdConvertPosition(newOrigin.simdWorldPosition, to: sphere2).rounded(.toNearestOrAwayFromZero))
             \(originInGlobalSpace.simdConvertPosition(originInGlobalSpace.simdWorldPosition, to: p))
             \(p.simdConvertVector(originInGlobalSpace.simdWorldPosition, from: originInGlobalSpace))
             \(newOrigin.simdConvertPosition(newOrigin.simdWorldPosition, to: sphere2))
             */
            
            //sphere2 = rotatePoint(node: sphere2, angle: -GLKMathRadiansToDegrees(diffRadiansX))
            
            
            
            

            
            //newOrigin.worldPosition.x = sphere2.simdWorldPosition.x
            //newOrigin.worldPosition.z = -sphere2.simdWorldPosition.z
            
            //newOrigin.worldPosition.y = rotatePoint(node: sphere2, angle: GLKMathRadiansToDegrees(diffRadiansX))
            //newOrigin.simdWorldPosition.x = 3
            
            
            //let diffRad = O.rotation.y - GLKQuaternionNormalize(GLKQuaternion(q: (p.rotation.x, p.rotation.y, p.rotation.z, p.rotation.w))).y
            
            //NotificationCenter.default.post(name: .genericMessage2, object: "rotation in degree from origin of second space with respect to last known point \(GLKMathRadiansToDegrees(diffRad))")
            
            
            //let rot = GLKQuaternionNormalize(GLKQuaternion(q: (knowPointIn2Space.rotation.x, knowPointIn2Space.rotation.y, knowPointIn2Space.rotation.z, knowPointIn2Space.rotation.w)))
            
            //knowPointIn2Space.rotation.x = rot.x
//            knowPointIn2Space.rotation = SCNVector4(0, rot.y, 0, rot.w)
            
            
            //NotificationCenter.default.post(name: .genericMessage2, object: "p:\n\(p.simdWorldTransform)\npnormalized:\n\(simd_float4(rot.x, rot.y, rot.z, rot.s))")
            
//            let knowPointIn2Space = projectNode(p, DictToRototraslation(name: "nil", traslation: a.traslation.inverse, r_Y: a.r_Y.inverse))
            
//            let notNorm = knowPointIn2Space.rotation
            //knowPointIn2Space.rotation.x = 0
            //knowPointIn2Space.rotation.z = 0
            
//            let rot = GLKQuaternionNormalize(GLKQuaternion(q: (knowPointIn2Space.rotation.x, knowPointIn2Space.rotation.y, knowPointIn2Space.rotation.z, knowPointIn2Space.rotation.w)))
            
            //knowPointIn2Space.rotation.x = rot.x
//            knowPointIn2Space.rotation = SCNVector4(0, rot.y, 0, rot.w)
            //knowPointIn2Space.simdRotation = simd_float4(rot.x, rot.y, rot.z, rot.s)
            

            
//            NotificationCenter.default.post(name: .genericMessage2, object: "rotation in degree from origin of second space with respect to last known point \(GLKMathRadiansToDegrees(rot.y))")
            
//            let diffDefree = -GLKMathRadiansToDegrees(rot.y)
            
            //NotificationCenter.default.post(name: .genericMessage2, object: "knowpoint2space:\n\(knowPointIn2Space.rotation)\norigin:\n\(O.rotation)\nnotNorm\(notNorm)")
            
            //knowPointIn2Space.simdRotation = simd_precise_normalize(knowPointIn2Space.simdRotation)
            //let transformation = knowPointIn2Space.simdWorldTransform.inverse * O.simdWorldTransform
            /*var transformation = simd_float4x4([
                simd_float4(cos(diffDefree),0.0,sin(diffDefree),0.0),
                simd_float4(0.0,1.0,0.0,0.0),
                simd_float4(-sin(diffDefree),0.0,cos(diffDefree),0.0),
                simd_float4(0.0,0.0,0.0,1.0)
            ])*/
            //transformation.columns.0.x = cos(diffDefree * Float.pi / 180)
            //transformation.columns.0.z = -sin(diffDefree * Float.pi / 180)
            //transformation.columns.2.x = sin(diffDefree * Float.pi / 180)
            //transformation.columns.2.z = cos(diffDefree * Float.pi / 180)
            
            //sceneView.session.setWorldOrigin(relativeTransform: transformation)
            
            //origin.position.x = O.position.x - p.position.x
            //origin.position.y = O.position.y - p.position.y
            //origin.position.z = O.position.z - p.position.z
            //print(O.simdWorldTransform)
            //print(p.simdWorldTransform)
            //origin.orientation.x = (O.orientation.x - p.orientation.x)
            //origin.orientation.y = (O.orientation.y - p.orientation.y)
            //origin.orientation.z = (O.orientation.z - p.orientation.z)
            //origin.orientation.w = (O.orientation.w - p.orientation.w)
            //let wTrans = (p * a).inverse
            //let x = p - (simd_float4x4([1.0,0,0,0],[0,1.0,0,0],[0,0,1.0,0],[0,0,0,1.0]) * a.inverse) - simd_float4x4([1.0,0,0,0],[0,1.0,0,0],[0,0,1.0,0],[0,0,0,1.0])
            //sceneView.scene.rootNode.simdWorldPosition = simd_float3(wTrans.columns.3.x, wTrans.columns.3.y, wTrans.columns.3.z)
            
            /*sceneView.scene.rootNode.setWorldTransform(
                SCNMatrix4(
                    m11: wTrans.columns.0.x, m12: wTrans.columns.0.y, m13: wTrans.columns.0.z, m14: wTrans.columns.0.w,
                    m21: wTrans.columns.1.x, m22: wTrans.columns.1.y, m23: wTrans.columns.1.z, m24: wTrans.columns.1.w,
                    m31: wTrans.columns.2.x, m32: wTrans.columns.2.y, m33: wTrans.columns.2.z, m34: wTrans.columns.2.w,
                    m41: wTrans.columns.3.x, m42: wTrans.columns.3.y, m43: wTrans.columns.3.z, m44: wTrans.columns.3.w
                )
            )*/
            
            /*for anchor in worldMap.anchors {
                guard !(anchor is ARPlaneAnchor) else { return }
                var color = UIColor(red: 255, green: 255, blue: 255, alpha: 1.0)
                if let n = anchor.name, n.hasPrefix("door") {color = UIColor(red: 255, green: 0, blue: 0, alpha: 1.0)}
                if let n = anchor.name, n.hasPrefix("wall") {color = UIColor(red: 0, green: 255, blue: 0, alpha: 1.0)}
                
                let sphereNode = generateSphereNode(color, 0.05)
                sphereNode.simdWorldTransform = anchor.transform
                DispatchQueue.main.async {
                    sceneView.scene.rootNode.addChildNode(sphereNode)
                }
                
            }*/
            
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
        
        
        var msg = ""
        
        if let camera = self.sceneView?.session.currentFrame?.camera {
            //CMMotionDetector.shared.stopDeviceMotionUpdates()
            DispatchQueue.main.async {NotificationCenter.default.post(name: .trackingPosition, object: camera.transform)}
            /*NotificationCenter.default.post(name: .genericMessage3, object: """
                rotXYZ: \(GLKMathRadiansToDegrees(camera.eulerAngles.x).rounded()) \(GLKMathRadiansToDegrees(camera.eulerAngles.y).rounded()) \(GLKMathRadiansToDegrees(camera.eulerAngles.z).rounded())
                posXYZ: \((camera.transform.columns.3.x * 1000).rounded() / 1000) \((camera.transform.columns.3.y * 1000).rounded() / 1000) \((camera.transform.columns.3.z * 1000).rounded() / 1000)
             """)*/
        }
        
        
        if trState == self.sceneView?.session.currentFrame?.camera.trackingState{return}
        trState=self.sceneView?.session.currentFrame?.camera.trackingState
        
        /*if (self.sceneView?.session.currentFrame?.camera.trackingState == .normal) {
            print(self.sceneView?.session.currentFrame?.camera.transform)
        }*/
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
