//
//  ConvertionLocalGlobal.swift
//  autoMapping
//
//  Created by student on 27/11/23.
//

import SwiftUI
import SceneKit



struct ConvertionLocalGlobal: View {
    
    @State var selectedMap = ""
    
    @State var selectedLocalNodeName = ""
    @State var selectedGlobalNodeName = ""
    
    @State var selectedLocalNode: SCNNode?
    @State var selectedGlobalNode: SCNNode?
    
    var globalView: SCNViewContainer
    var localView: SCNViewContainer
    let localMaps: [URL]?
    
    @State var globalNodes: [String]
    @State var localNodes: [String] = []
    
    @State var matchingNodesForAPI: [(SCNNode,SCNNode)] = []
    
    
    @State var apiResponseCode = ""
    
    @State var responseFromServer = false
    @State var response: (HTTPURLResponse?, [String: Any]) = (nil, ["":""])
    
    
    
    init() {
        globalView = SCNViewContainer()
        localView = SCNViewContainer()
        localMaps = listOfFilesURL(path: ["Maps"])
        
        
        globalView.loadgeneralMap(borders: false)
        globalNodes = globalView.scnView.scene?.rootNode.childNodes(passingTest: {
            n,_ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
        }).map{node in node.name ?? "nil"} ?? []
        //print(globalNodes)
    }
    
    var body: some View {
        
        if !responseFromServer {
            //global map
            Text("Global Map")
            Button("zoom in"){
                globalView.zoomIn()
            }.buttonStyle(.bordered)
            Button("zoom out"){
                globalView.zoomOut()
            }.buttonStyle(.bordered)
            globalView
            HStack {
                Picker("choose global node", selection: $selectedGlobalNodeName) {
                    Text("")
                    ForEach(globalNodes, id: \.self) {Text($0)}
                }.onChange(of: selectedGlobalNodeName, perform: { _ in
                    globalView.changeColorOfNode(nodeName: selectedGlobalNodeName, color: UIColor.green)
                    selectedGlobalNode = globalView.scnView.scene?.rootNode.childNodes(passingTest: {n,_ in n.name != nil && n.name! == selectedGlobalNodeName}).first
                })
                if let _size = selectedGlobalNode?.scale {Text("\(_size.x) \(_size.y) \(_size.z)")}
            }

            
            Divider()
            
            //local map
            if let _localMaps = localMaps {
                HStack{
                    Text("local maps availables: \(_localMaps.count.codingKey.stringValue)")
                    Text("Selected map: \(selectedMap)")
                }
                Picker("Please choose a color", selection: $selectedMap) {
                    Text("")
                    ForEach(_localMaps, id: \.lastPathComponent) {Text($0.lastPathComponent)}
                }.onChange(of: selectedMap, perform: { _ in
                    localView.loadRoomMaps(name: selectedMap, borders: false)
                    localNodes = localView.scnView.scene?.rootNode.childNodes(passingTest: {
                        n,_ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
                    })
                    .sorted(by: {a,b in a.scale.x>b.scale.x})
                    .map{node in node.name ?? "nil"} ?? []
                })
            }
            if selectedMap != "" {
                Button("zoom in"){
                    localView.zoomIn()
                }.buttonStyle(.bordered)
                Button("zoom out"){
                    localView.zoomOut()
                }.buttonStyle(.bordered)
                localView
                HStack {
                    Picker("choose node", selection: $selectedLocalNodeName) {
                        Text("")
                        ForEach(localNodes, id: \.self) {Text($0)}
                    }.onChange(of: selectedLocalNodeName, perform: { _ in
                        localView.changeColorOfNode(nodeName: selectedLocalNodeName, color: UIColor.green)
                        selectedLocalNode = localView.scnView.scene?.rootNode.childNodes(passingTest: {n,_ in n.name != nil && n.name! == selectedLocalNodeName}).first
                        globalNodes = orderBySimilarity(
                            node: selectedLocalNode!,
                            listOfNodes: globalView.scnView.scene!.rootNode.childNodes(passingTest: {
                                n,_ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp" && n.name! != "__selected__"
                            })
                        ).map{node in node.name ?? "nil"}
                    })
                    if let _size = selectedLocalNode?.scale {Text("\(_size.x) \(_size.y) \(_size.z)")}
                }
                
                
            }
            HStack {
                if let _selectedLocalNode = selectedLocalNode, let _selectedGlobalNode = selectedGlobalNode {
                    Button("confirm relation"){
                        //print(selectedLocalNode)
                        //print(selectedGlobalNode)
                        matchingNodesForAPI.append((_selectedLocalNode, _selectedGlobalNode))
                        print(selectedMap)
                        print(matchingNodesForAPI)
                    }.buttonStyle(.bordered)
                }
                Text("matched nodes: \(matchingNodesForAPI.count)")
                if matchingNodesForAPI.count >= 3 {
                    Button("ransac Alignment API"){
                        //print(selectedMap)
                        //print(matchingNodesForAPI)
                        Task {
                            response = try await fetchAPIConversionLocalGlobal(localName: selectedMap, nodesList: matchingNodesForAPI)
                            responseFromServer = true
                        }
                    }.buttonStyle(.bordered)
                }
            }
        }
        
        if responseFromServer {
            Text("visualize response")
            if let _res = response.0 {Text("status code: \(_res.statusCode)")}
            let _ = print(response.1)
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(response.1.sorted(by: {a,b in a.key.count > b.key.count}), id: \.key) { k,v in
                        if k=="err" {
                            Text("\(k) -> \(v as! String)")
                        } else {
                            let _v = v as! [String: Any]
                            Text(k)
                            if let reg_result = _v["reg_result"] as? String {Text(reg_result)}
                            Text("R_Y")
                            Text(printMatrix(matrix: _v["R_Y"] as! [[Double]], decimal: 4))
                            
                            Text("diffMatrices")
                            Text(printMatrix(matrix: _v["diffMatrices"] as! [[Double]], decimal: 4))
                            
                            Text("translation")
                            Text(printMatrix(matrix: _v["translation"] as! [[Double]], decimal: 4))
                            
                        }
                        
                        Divider()
                    }
                }
                Button("save response"){
                    saveConversionGlobalLocal(response.1)
                }.buttonStyle(.bordered)
            }
        }
        
        
        
    }
}

#Preview {
    ConvertionLocalGlobal()
}
