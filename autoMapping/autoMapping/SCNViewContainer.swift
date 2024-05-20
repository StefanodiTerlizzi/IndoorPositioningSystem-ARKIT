//
//  SCNViewContainer.swift
//  autoMapping
//
//  Created by Stefano di Terlizzi on 12/07/23.
//

import SwiftUI
import SceneKit
import ComplexModule
import ARKit
import RoomPlan
import CoreMotion

struct SCNViewContainer: UIViewRepresentable {
    
    typealias UIViewType = SCNView
    
    var scnView = SCNView(frame: .zero)
    
    var handler = HandleTap()
    
    var cameraNode = SCNNode()
    var massCenter = SCNNode()
    
    var delegate = RenderDelegate()
    
    var dimension = SCNVector3()
    
    var rotoTraslation: [DictToRototraslation] = []
    
    @State var rotoTraslationActive: Int = 0
    
    init() {
        print("init SCNViewContainer")
        massCenter.worldPosition = SCNVector3(0, 0, 0)
    }
    
    func RotoActivePlusMinus(_ plus: Bool) {
        if (plus) {
            rotoTraslationActive = (rotoTraslationActive + 1) % rotoTraslation.count
        } else {
            rotoTraslationActive = (rotoTraslationActive - 1) % rotoTraslation.count
        }
    }
    
    func loadgeneralMap(borders: Bool, name: String) {
        
        scnView.scene = try! SCNScene(url: Model
            .shared
            .directoryURL
            .appending(path: "ExportCombined")
            .appending(path: "\(name).usdz"))
        
        //print("--> LOADING GLOBAL MAP TO CONVERTION")
        //print(scnView.scene)
        
        drawContent(borders: borders)
        setMassCenter()
        setCamera()
        NotificationCenter
            .default
            .post(name: .genericMessage, object: "map loaded correctly")
    }
    
    func loadRoomMaps(name: String, borders: Bool) {
        scnView.scene = try! SCNScene(url: Model.shared.directoryURL
            .appending(path: "MapUsdz")
            .appending(path: "\(name).usdz"))
        //print("load single map")
        drawContent(borders: borders)
        
        setMassCenter()
        setCamera()
        NotificationCenter
            .default
            .post(name: .genericMessage, 
                  object: "map loaded correctly")
    }
    
    func setCamera() {
        scnView.scene?.rootNode.addChildNode(cameraNode)
        cameraNode.camera = SCNCamera()
        cameraNode.worldPosition = massCenter.worldPosition
        
        cameraNode.worldPosition.y = 10
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = 10
        // Create directional light
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light!.type = .ambient
        directionalLight.light!.color = UIColor(white: 1.0, alpha: 1.0)
        cameraNode.addChildNode(directionalLight)
        
        scnView.pointOfView = cameraNode
        let vConstraint = SCNLookAtConstraint(target: massCenter)
        cameraNode.constraints = [vConstraint]
        directionalLight.constraints = [vConstraint]
    }
    
    func setMassCenter() {
        var massCenter = SCNNode()
        massCenter.worldPosition = SCNVector3(0, 0, 0)
        if let nodes = scnView.scene?.rootNode
            .childNodes(passingTest: {
                n,_ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
            }) {
            massCenter = findMassCenter(nodes)
        }
        scnView.scene?.rootNode.addChildNode(massCenter)
    }
    
    func drawContent(borders: Bool) {
        //print("draw content")
        //add room content
        print(borders)
        
        scnView.scene?
            .rootNode
            .childNodes(passingTest: {
                n,_ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp" && n.name! != "__selected__"
            })
            .forEach{
                //print($0.name)
                //print($0.scale)
                let material = SCNMaterial()
                material.diffuse.contents = UIColor.black
                if ($0.name!.prefix(5) == "Floor") {material.diffuse.contents = UIColor.white.withAlphaComponent(0.2)}
                if ($0.name!.prefix(4) == "Door" || $0.name!.prefix(4) == "Open") {material.diffuse.contents = UIColor.red}
                material.lightingModel = .physicallyBased
                $0.geometry?.materials = [material]
                //let angle = $0.eulerAngles.y
                //$0.eulerAngles.y -= angle
                if borders {
                    //print("draw borders")
                    $0.scale.x = $0.scale.x < 0.2 ? $0.scale.x + 0.1 : $0.scale.x
                    $0.scale.z = $0.scale.z < 0.2 ? $0.scale.z + 0.1 : $0.scale.z
                    $0.scale.y = ($0.name!.prefix(4) == "Wall") ? 0.1 : $0.scale.y
                }
                //$0.eulerAngles.y = angle
            }
    }
    
    func drawOrigin(_ o: SCNVector3,_ color: UIColor, _ size: CGFloat, _ addY: Bool = false) {
        
        let sphere = generateSphereNode(color, size)
        sphere.name = "Origin"
        
        print("Origin Drawn")
        print(sphere.worldTransform)
        
        sphere.simdWorldPosition = simd_float3(o.x, o.y, o.z)
        
        print(sphere.worldTransform)
        
        if let r = Model.shared.actualRoto {sphere.simdWorldTransform = simd_mul(sphere.simdWorldTransform, r.traslation)}
        sphere.worldPosition.y -= 1
        if addY {sphere.worldPosition.y += 1}
        
        scnView.scene?.rootNode.addChildNode(sphere)
         
    }
    
    func addBoundingBox(bb: [SCNNode], color: UIColor) {
        
        for e in bb {
            var sphere = generateSingleSphereNode(color, 0.5)
            sphere.simdWorldPosition = e.simdWorldPosition
            scnView.scene?.rootNode.addChildNode(sphere)
        }
        
        /*
        var sphere1 = generateSingleSphereNode(UIColor.magenta, 0.5)
        sphere1.simdWorldPosition = simd_float3(bb.0.0, 3, bb.0.1)
        scnView.scene?.rootNode.addChildNode(sphere1)
        
        var sphere2 = generateSingleSphereNode(UIColor.magenta, 0.5)
        sphere2.simdWorldPosition = simd_float3(bb.0.0, 3, bb.1.1)
        scnView.scene?.rootNode.addChildNode(sphere2)
        
        var sphere3 = generateSingleSphereNode(UIColor.magenta, 0.5)
        sphere3.simdWorldPosition = simd_float3(bb.1.0, 3, bb.1.1)
        scnView.scene?.rootNode.addChildNode(sphere3)
        
        var sphere4 = generateSingleSphereNode(UIColor.magenta, 0.5)
        sphere4.simdWorldPosition = simd_float3(bb.1.0, 3, bb.0.1)
        scnView.scene?.rootNode.addChildNode(sphere4)
         */
    }
    
    func zoomIn() {cameraNode.camera?.orthographicScale -= 0.5}
    
    func zoomOut() {cameraNode.camera?.orthographicScale += 0.5}
    
    func unloadFeaturesPoints() {
        scnView.scene?.rootNode.childNodes.filter({ $0.name == "featurePoint" }).forEach({ $0.removeFromParentNode() })
    }
    
    func loadFeaturesPoints(_ color: UIColor, _ rototraslation: DictToRototraslation?, map: ARWorldMap) {
        print("load features point with \(rototraslation?.name)")
        scnView.scene?.rootNode.childNodes.filter({ $0.name == "featurePoint" }).forEach({ $0.removeFromParentNode() })
        //add sphere for features points
        print(color)
        for (index, p) in map.rawFeaturePoints.points.enumerated() {
            //if index%20 != 0 {continue}
            let sphere = generateSingleSphereNode(color, 0.1)
            sphere.name = "featurePoint"
            sphere.simdWorldPosition = p
            if let r = rototraslation {sphere.simdWorldTransform = simd_mul(sphere.simdWorldTransform, r.traslation)}
            scnView.scene?.rootNode.addChildNode(sphere)
        }
        NotificationCenter.default.post(name: .genericMessage, object: "features points loaded correctly")
    }
    
    func updatePosition(_ pos: simd_float4x4, _ rototraslation: DictToRototraslation?) {
        print("UPDATE position with \(rototraslation?.name)")
        
        //remove position node
        scnView.scene?
            .rootNode
            .childNodes
            .filter({ $0.name == "POS" })
            .forEach({ $0.removeFromParentNode() })
        
        //add position node
        var sphere = generateSphereNode(UIColor(red: 0, green: 0, blue: 255, alpha: 1.0), 0.2)
    
        //sphere.rotation.x = 0
        //sphere.rotation.z = 0
        //sphere.simdWorldPosition = simd_float3(pos.columns.3.x, pos.columns.3.y, pos.columns.3.z)
        sphere.simdWorldTransform = pos
        sphere.simdLocalRotate(by: simd_quatf(angle: GLKMathDegreesToRadians(90.0), axis: [0,0,1]))
        
        if let r = rototraslation {
            
            sphere = projectNode(sphere, r)
            
            Model.shared.lastKnowPositionInGlobalSpace = sphere
            
            //draw origin in global space
            scnView.scene?
                .rootNode
                .childNodes
                .filter({ $0.name == "ORIGININGLOBALSPACE" }).forEach({ $0.removeFromParentNode() })
            
            var O = generateSphereNode(UIColor(red: 0, green: 255, blue: 0, alpha: 1.0), 0.2)
            O.simdWorldTransform = (Model.shared.origin.copy() as! SCNNode).simdWorldTransform
            //O.simdLocalRotate(by: simd_quatf(angle: GLKMathDegreesToRadians(90.0), axis: [0,0,1]))
            O = projectNode(O, r)
            O.name = "ORIGININGLOBALSPACE"
            scnView.scene?.rootNode.addChildNode(O)
            
            //draw last known position in global space
//            if let lastKnowPositionInGlobalSpace = Model.shared.lastKnowPositionInGlobalSpace {
//                scnView.scene?.rootNode.childNodes.filter({ $0.name == "POS2" }).forEach({ $0.removeFromParentNode() })
//                var sphere2 = generateSphereNode(UIColor(red: 255, green: 0, blue: 0, alpha: 1.0), 0.2)
//                sphere2.simdWorldTransform = lastKnowPositionInGlobalSpace.simdWorldTransform
//                
//                sphere2.name = "POS2"
//                scnView.scene?.rootNode.addChildNode(sphere2)
//            }
            
        }
        
        sphere.name = "POS"
        scnView.scene?.rootNode.addChildNode(sphere)
    }
    
    func findMassCenter(_ nodes: [SCNNode]) -> SCNNode {
        let massCenter = SCNNode()
        var X: [Float] = [Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude]
        var Z: [Float] = [Float.greatestFiniteMagnitude, -Float.greatestFiniteMagnitude]
        for n in nodes{
            if (n.worldPosition.x < X[0]) {X[0] = n.worldPosition.x}
            if (n.worldPosition.x > X[1]) {X[1] = n.worldPosition.x}
            if (n.worldPosition.z < Z[0]) {Z[0] = n.worldPosition.z}
            if (n.worldPosition.z > Z[1]) {Z[1] = n.worldPosition.z}
        }
        massCenter.worldPosition = SCNVector3((X[0]+X[1])/2, 0, (Z[0]+Z[1])/2)
        return massCenter
    }
    
    func setupCamera(cameraNode: SCNNode){
        cameraNode.camera = SCNCamera()
        //scnView.scene = try! SCNScene(url: Model.shared.usdzURL!)
        //scnView.scene = try! SCNScene(named: "Room.usdz")!
        
        scnView.scene?.rootNode.addChildNode(cameraNode)
        let wall = scnView.scene?.rootNode
            .childNodes(passingTest: {
                n,_ in n.name != nil && n.name! == "Wall0"
            })[0]
        
        print("root/Node -> \(scnView.scene!.rootNode.worldOrientation)")
        var X: [Float] = [1000000.0, -1000000.0]
        var Z: [Float] = [1000000.0, -1000000.0]
        
        var massCenter = SCNNode()
        
        scnView.scene?.rootNode
            .childNodes(passingTest: {
                n,_ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
            })
            .forEach{
      
                let material = SCNMaterial()
                material.diffuse.contents = ($0.name!.prefix(4) == "Door" || $0.name!.prefix(4) == "Open") ? UIColor.white : UIColor.black
                material.lightingModel = .physicallyBased
                //sphere1.materials = [sphere1Material]
                $0.geometry?.materials = [material]
                //$0.geometry?.firstMaterial?.diffuse.contents = Color(.blue)
                //$0.light?.color = Color.red
                //tappedNode.name! += "_tapped"
                if ($0.worldPosition.x < X[0]) {X[0] = $0.worldPosition.x}
                if ($0.worldPosition.x > X[1]) {X[1] = $0.worldPosition.x}
                if ($0.worldPosition.z < Z[0]) {Z[0] = $0.worldPosition.z}
                if ($0.worldPosition.z > Z[1]) {Z[1] = $0.worldPosition.z}
                print("\($0.name), \($0.worldPosition)")
                /*let angle = $0.eulerAngles.y
                $0.eulerAngles.y -= angle
                $0.scale.x = $0.scale.x < 0.2 ? $0.scale.x + 0.1 : $0.scale.x
                $0.scale.z = $0.scale.z < 0.2 ? $0.scale.z + 0.1 : $0.scale.z
                $0.scale.y = ($0.name!.prefix(4) == "Door" || $0.name!.prefix(4) == "Open") ? wall!.scale.y*2 : $0.scale.y
                $0.eulerAngles.y = angle*/
            }
        massCenter.worldPosition = SCNVector3((X[0]+X[1])/2, 0, (Z[0]+Z[1])/2)
        //print(X)
        //print(Z)
        cameraNode.worldPosition = massCenter.worldPosition
        //cameraNode.worldPosition = SCNVector3((scnView.scene?.rootNode.worldPosition.x)!, 100, (scnView.scene?.rootNode.worldPosition.z)!)
        cameraNode.worldPosition.y = 10
        cameraNode.camera?.usesOrthographicProjection = true
        cameraNode.camera?.orthographicScale = 20
        cameraNode.rotation.y = wall!.rotation.y
        cameraNode.rotation.w = wall!.rotation.w
        // Create directional light
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light!.type = .ambient
        directionalLight.light!.color = UIColor(white: 1.0, alpha: 1.0)
        
        //directionalLight.eulerAngles = SCNVector3(x: 0, y: 0, z: 0)
        cameraNode.addChildNode(directionalLight)
        
        scnView.pointOfView = cameraNode
        
        scnView.scene?.rootNode.addChildNode(massCenter)

        let vConstraint = SCNLookAtConstraint(target: massCenter)
        cameraNode.constraints = [vConstraint]
        directionalLight.constraints = [vConstraint]
        
    }
    
    func changeColorOfNode(nodeName: String, color: UIColor) {
        drawContent(borders: false)
        if let _node = scnView.scene?.rootNode.childNodes(passingTest: { n,_ in n.name != nil && n.name! == nodeName }).first {
            var copy = _node.copy() as! SCNNode
            copy.name = "__selected__"
            let material = SCNMaterial()
            material.diffuse.contents = color
            material.lightingModel = .physicallyBased
            copy.geometry?.materials = [material]
            copy.worldPosition.y += 4
            copy.scale.x = _node.scale.x < 0.2 ? _node.scale.x + 0.1 : _node.scale.x
            copy.scale.z = _node.scale.z < 0.2 ? _node.scale.z + 0.1 : _node.scale.z
            scnView.scene?.rootNode.addChildNode(copy)
        }
    }
    
    func makeUIView(context: Context) -> SCNView {
        //scnView.allowsCameraControl = true
        //scnView.autoenablesDefaultLighting = true
        //scnView.scene = try! SCNScene(url: Model.shared.usdzURL!)
        //scnView.scene = try! SCNScene(named: "Room.usdz")!
        //scnView.backgroundColor = UIColor.darkGray
        // add a tap gesture recognizer
        print("add a tap gesture recognizer")
        handler.scnView = scnView
        let tapGesture = UIGestureRecognizer(
            target: self,
            action: #selector(self.handler.handleTap(_:))
        )
        scnView.addGestureRecognizer(tapGesture)
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}
}

class HandleTap: UIViewController {
    var scnView: SCNView?
    
    @objc func handleTap(_ gestureRecognize: UITapGestureRecognizer) {
         print("handleTap")
        /*guard let renderer = delegate.lastRenderer else { return }
        let hits = renderer.hitTest(event.location, options: nil)
        if let tappedNode = hits.first?.node {
            print(tappedNode)
        }*/
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView!.hitTest(p, options: nil)
        if let tappedNode = hitResults.first?.node {
            print(tappedNode)
        }
      }
}

@available(iOS 17.0, *)
struct SCNViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        SCNViewContainer()
    }
}

extension SCNQuaternion {
    func difference(_ other: SCNQuaternion) -> SCNQuaternion{
        return SCNQuaternion(
            self.x - other.x,
            self.y - other.y,
            self.z - other.z,
            self.w - other.w
        )
    }
    
    func sum(_ other: SCNQuaternion) -> SCNQuaternion{
        return SCNQuaternion(
            self.x + other.x,
            self.y + other.y,
            self.z + other.z,
            self.w + other.w
        )
    }
}

extension SCNVector3 {
    func difference(_ other: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            self.x - other.x,
            self.y - other.y,
            self.z - other.z
        )
    }
    
    func sum(_ other: SCNVector3) -> SCNVector3 {
        return SCNVector3(
            self.x + other.x,
            self.y + other.y,
            self.z + other.z
        )
    }
    
    func rotateAroundOrigin(_ angle: Float) -> SCNVector3 {
        var a = Complex<Float>.i
        a.real = cos(angle)
        a.imaginary = sin(angle)
        var b = Complex<Float>.i
        b.real = self.x
        b.imaginary = self.z
        var position = a*b
        return SCNVector3(
            position.real,
            self.y,
            position.imaginary
        )
    }
}

extension SCNNode {
    
    var height: CGFloat { CGFloat(self.boundingBox.max.y - self.boundingBox.min.y) }
    var width: CGFloat { CGFloat(self.boundingBox.max.x - self.boundingBox.min.x) }
    var length: CGFloat { CGFloat(self.boundingBox.max.z - self.boundingBox.min.z) }
    
    var halfCGHeight: CGFloat { height / 2.0 }
    var halfHeight: Float { Float(height / 2.0) }
    var halfScaledHeight: Float { halfHeight * self.scale.y  }
}

struct DictToRototraslation {
    
    let name: String
    let traslation: simd_float4x4
    let r_Y: simd_float4x4
    
}
