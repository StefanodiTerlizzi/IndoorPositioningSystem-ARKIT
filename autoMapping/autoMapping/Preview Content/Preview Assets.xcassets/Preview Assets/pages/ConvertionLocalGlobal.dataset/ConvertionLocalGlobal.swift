//
//  ConvertionLocalGlobal.swift
//  autoMapping
//
//  Created by student on 27/11/23.
//

import SwiftUI
import SceneKit


struct ConvertionLocalGlobal: View {
    
    //@State var selectedMap = ""
    
    @State var selectedLocalNodeName = ""
    @State var selectedGlobalNodeName = ""
    
    @State var selectedLocalNode: SCNNode?
    @State var selectedGlobalNode: SCNNode?
    
    var globalView: SCNViewContainer
    var localView: SCNViewContainer
    let localMaps: [URL]?
    //let globalMaps: [URL]?
    
    @State var globalNodes: [String]
    @State var localNodes: [String] = []
    
    @State var matchingNodesForAPI: [(SCNNode,SCNNode)] = []
    
    @State var apiResponseCode = ""
    
    @State var responseFromServer = false
    @State var response: (HTTPURLResponse?, [String: Any]) = (nil, ["":""])
    
    @State private var showButton1 = false
    @State private var showButton2 = false
    
    @State private var mapName : String = ""
    
    @State private var selectedMap: String = ""
    @State private var availableMaps: [String] = []
    @State private var filteredLocalMaps: [String] = []
    
    
    func printOriginalDimensionsOfSelectedNode(selectedNode: SCNNode) {
        if let geometry = selectedNode.geometry {
            switch geometry {
            case let box as SCNBox:
                print("Nodo: \(selectedNode.name ?? "sconosciuto"), Tipo: Box, Dimensioni originali: larghezza: \(box.width), altezza: \(box.height), lunghezza: \(box.length)")
            case let sphere as SCNSphere:
                print("Nodo: \(selectedNode.name ?? "sconosciuto"), Tipo: Sphere, Diametro originale: \(sphere.radius * 2)")
            case let cylinder as SCNCylinder:
                print("Nodo: \(selectedNode.name ?? "sconosciuto"), Tipo: Cylinder, Altezza originale: \(cylinder.height), Diametro originale: \(cylinder.radius * 2)")
            case let cone as SCNCone:
                print("Nodo: \(selectedNode.name ?? "sconosciuto"), Tipo: Cone, Altezza originale: \(cone.height), Diametro alla base originale: \(cone.topRadius * 2)")
            case let plane as SCNPlane:
                print("Nodo: \(selectedNode.name ?? "sconosciuto"), Tipo: Plane, Dimensioni originali: larghezza: \(plane.width), altezza: \(plane.height)")
                // Aggiungi qui altri casi per diversi tipi di geometrie se necessario
            default:
                print("Geometria non supportata per il calcolo delle dimensioni.")
            }
        } else {
            print("Il nodo selezionato non ha una geometria associata.")
        }
    }
    
    //    func updateGlobalNodes(selectedLocalNodeName: String) {
    //        guard let firstTwoLetters = selectedLocalNodeName.prefix(2) as! String? else {
    //            return
    //        }
    //
    //        globalNodes = globalView.scnView.scene?.rootNode.childNodes(passingTest: { node, _ in
    //            guard let nodeName = node.name else { return false }
    //            return nodeName.starts(with: firstTwoLetters) &&
    //                nodeName != "Room" &&
    //                nodeName != "Geom" &&
    //                !nodeName.hasSuffix("_grp")
    //        }).map { node in
    //            node.name ?? "nil"
    //        } ?? []
    //    }
    //
    
    //    private func loadMaps() {
    //        // Carica l'elenco delle mappe dal filesystem
    //        let directoryURL = Model.shared.directoryURL.appending(path: "ExportCombined")
    //        let fileManager = FileManager.default
    //
    //        do {
    //            let mapFiles = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
    //
    //            print(mapFiles)
    //            // Filtra i file per mantenere solo quelli con estensione .usdz
    //            let usdzFiles = mapFiles.filter { $0.pathExtension == "usdz" }
    //
    //            print("usdz: \(usdzFiles)")
    //
    //            availableMaps = usdzFiles.map { $0.lastPathComponent }
    //
    //            print("mapName: \(availableMaps)")
    //
    //
    //            if let firstMap = availableMaps.first {
    //                print("firstMap: \(firstMap)")
    //                selectedMap = firstMap
    //                filterLocalMaps()
    //            }
    //        } catch {
    //            print("Errore durante il caricamento delle mappe: \(error)")
    //            availableMaps = []
    //        }
    //    }
    
    init() {
        
        globalView = SCNViewContainer()
        localView = SCNViewContainer()
        localMaps = listOfFilesURL(path: ["Maps"])
        
        //let usdzFiles2 = usdzFiles.map {$0.lastPathComponent}
        
        
        //print("GlobalMaps: \(globalMaps)\n\n\n\n")
        
        
        
        //        print(localMaps)
        //        if let firstMapURL = localMaps?.first,
        //           let mapName = firstMapURL.lastPathComponent.components(separatedBy: CharacterSet.decimalDigits).first {
        //            print("mapName: ---> \(mapName)")
        //            globalView.loadgeneralMap(borders: false, name: mapName)
        //        }
        
        //globalView.loadgeneralMap(borders: false, name: "Lab")
        
        
        globalNodes = globalView
            .scnView
            .scene?
            .rootNode
            .childNodes(passingTest: {
                n,
                _ in n.name != nil &&
                n.name! != "Room" &&
                n.name! != "Geom" &&
                String(n.name!.suffix(4)) != "_grp"
            }).map{node in node.name ?? "nil"} ?? []
        //loadMaps()
        
//                globalMaps = listOfFilesURL(path: ["ExportCombined"])
//                let usdzFiles = globalMaps?.filter{ $0.pathExtension == "usdz"}
//                for mapURL in usdzFiles ?? [] {
//                    let mapName = mapURL.deletingPathExtension().lastPathComponent
//                    print("mapName: ---> \(mapName)")
//                    availableMaps.append(mapName)
//                }
//        
//                print(availableMaps)
        
        
    }
    
    
    //    func makeUIView(context: Context) -> SCNView {
    //            // Carica l'elenco delle mappe quando la vista viene creata
    //            loadMaps()
    //            return scnView
    //        }
    //
    //        func updateUIView(_ uiView: SCNView, context: Context) {}
    
    
    
    //    private func filterLocalMaps() {
    //        filteredLocalMaps = availableMaps.filter { $0.hasPrefix(selectedMap) }
    //    }
    
    var body: some View {
        VStack{
            if !responseFromServer {
                
                VStack{
                    Text("CREATE MATRIX").bold().font(.largeTitle)
                    //global map
                    Text("GLOBAL Map").bold().font(.title3)
                }
                
                HStack{
                    Button("+"){
                        globalView.zoomIn()
                    }.buttonStyle(.bordered).bold().background(Color(red: 255/255, green: 235/255, blue: 205/255)).cornerRadius(8)
                    Button("-"){
                        globalView.zoomOut()
                    }.buttonStyle(.bordered).bold().background(Color(red: 255/255, green: 235/255, blue: 205/255)).cornerRadius(8)
                }
                
                globalView
                    .border(Color.white)
                    .padding()
                    .shadow(color: Color.gray, radius: 3)
                
                HStack {
                    Picker("Choose Global Node", selection: $selectedGlobalNodeName) {
                        Text("Choose Global Node")
                        ForEach(globalNodes, id: \.self) {Text($0)}
                    }.onChange(of: selectedGlobalNodeName, perform: { _ in
                        globalView.changeColorOfNode(nodeName: selectedGlobalNodeName, color: UIColor.green)
                        
                        let firstTwoLetters = String(selectedGlobalNodeName.prefix(2))
                        
                        localNodes = localView.scnView.scene?.rootNode.childNodes(passingTest: {
                            n, _ in n.name != nil && n.name!.starts(with: firstTwoLetters) && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
                        })
                        .sorted(by: {a, b in a.scale.x > b.scale.x})
                        .map{node in node.name ?? "nil"} ?? []
                        
                        //print("\n\n\(localNodes)\n\n")
                        
                        selectedGlobalNode = globalView.scnView.scene?.rootNode.childNodes(passingTest: {n,_ in n.name != nil && n.name! == selectedGlobalNodeName}).first
                        
                    })
                    
                    
                    if let _size = selectedGlobalNode?.scale {Text("\(_size.x) \(_size.y) \(_size.z)")
                    }
                    
                }
                
                Divider().background(Color.black).shadow(radius: 100)
                
                //Local map
                if let _localMaps = localMaps {
                    HStack{
                        //Text("Local Maps Availables: \(_localMaps.count.codingKey.stringValue)")
                        //Text("Selected map: \(selectedMap)")
                        Text("LOCAL Map").bold().font(.title3)
                    }
                    Picker("", selection: $selectedMap) {
                        Text("Choose Local Map").foregroundColor(.white)
                        ForEach(_localMaps, id: \.lastPathComponent) {Text($0.lastPathComponent)}
                    }.onChange(of: selectedMap, perform: { _ in
                        localView.loadRoomMaps(name: selectedMap, borders: false)
                        
                        
                        let numbersCharacterSet = CharacterSet.decimalDigits
                        let map = selectedMap.components(separatedBy: numbersCharacterSet).joined()
                        
                        
                        globalView.loadgeneralMap(borders: false, name: map)
                        
                        localNodes = localView.scnView.scene?.rootNode.childNodes(passingTest: {
                            n,_ in n.name != nil && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
                        })
                        .sorted(by: {a,b in a.scale.x>b.scale.x})
                        .map{node in node.name ?? "nil"} ?? []
                        
                        print("Child Nodes: \(String(describing: localView.scnView.scene?.rootNode.childNodes))")
                    })
                }
                
                if selectedMap != "" {
                    HStack{
                        Button("+"){
                            localView.zoomIn()
                        }.buttonStyle(.bordered).bold().background(Color(red: 255/255, green: 235/255, blue: 205/255)).cornerRadius(6)
                        Button("-"){
                            localView.zoomOut()
                        }.buttonStyle(.bordered).bold().background(Color(red: 255/255, green: 235/255, blue: 205/255)).cornerRadius(6)
                        
                    }
                    
                    
                    localView
                        .border(Color.white)
                        .padding()
                        .shadow(color: Color.gray, radius: 3)
                    
                    
                    HStack {
                        Picker("", selection: $selectedLocalNodeName) {
                            Text("Choose Local Node").foregroundColor(.white)
                            ForEach(localNodes, id: \.self) {Text($0)}
                        }.onChange(of: selectedLocalNodeName, perform: { _ in
                            localView.changeColorOfNode(nodeName: selectedLocalNodeName, color: UIColor.green)
                            selectedLocalNode = localView.scnView.scene?.rootNode.childNodes(passingTest: {n,_ in n.name != nil && n.name! == selectedLocalNodeName}).first
                            
                            // updateGlobalNodes(selectedLocalNodeName: selectedLocalNodeName)
                            
                            let firstTwoLettersLocal = String(selectedLocalNodeName.prefix(2))
                            
                            globalNodes = globalView.scnView.scene?.rootNode.childNodes(passingTest: {
                                n, _ in n.name != nil && n.name!.starts(with: firstTwoLettersLocal) && n.name! != "Room" && n.name! != "Geom" && String(n.name!.suffix(4)) != "_grp"
                            })
                            .sorted(by: {a, b in a.scale.x > b.scale.x})
                            .map{node in node.name ?? "nil"} ?? []
                            
                            
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
                    if let _selectedLocalNode = selectedLocalNode,
                       let _selectedGlobalNode = selectedGlobalNode {
                        Button("confirm relation"){
                            
                            matchingNodesForAPI.append((_selectedLocalNode, _selectedGlobalNode))
                            print(_selectedLocalNode)
                            print(_selectedGlobalNode)
                            print(selectedMap)
                            print(matchingNodesForAPI)
                            
                        }.buttonStyle(.bordered)
                            .background(Color(red: 240/255, green: 151/255, blue: 45/255))
                            .cornerRadius(6)
                            .bold()
                    }
                    Text("matched nodes: \(matchingNodesForAPI.count)")
                    
                    
                    if matchingNodesForAPI.count >= 3 {
                        Button("ransac Alignment API"){
                            Task {
                                print(selectedMap)
                                print(matchingNodesForAPI)
                                response = try await fetchAPIConversionLocalGlobal(localName: selectedMap, nodesList: matchingNodesForAPI)
                                responseFromServer = true
                            }
                        }.buttonStyle(.bordered)
                            .background(Color(red: 255/255, green: 235/255, blue: 205/255))
                            .cornerRadius(6)
                            .bold()
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
                    Button("save response") {
                        saveConversionGlobalLocal(response.1)
                    }.buttonStyle(.bordered)
                        .background(Color(red: 255/255, green: 235/255, blue: 205/255))
                        .cornerRadius(6)
                        .bold()
                }
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 11/255, green: 121/255, blue: 157/255))
            .foregroundColor(.white)
    }
    
}
#Preview {
    ConvertionLocalGlobal()
}
