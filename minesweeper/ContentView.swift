//
//  ContentView.swift
//  Shared
//
//  Created by Ruslan Khyurri on 2/12/22.
//

import SwiftUI

enum GameObjectType {
    case mine
    case counter
}

struct GameObject: Identifiable {
    let id = UUID()
    let goType: GameObjectType
    var isOpen: Bool = false
    var isFlag: Bool = false
    var mineCount: Int
    
    init(_ goType: GameObjectType) {
        self.goType = goType
        self.mineCount = 0
    }
    
    init(_ goType: GameObjectType, mineCount: Int) {
        self.goType = goType
        self.mineCount = mineCount
    }
    
    
    func icon(forseOpen: Bool = false) -> String {
        if isOpen || forseOpen {
            switch goType {
            case .mine:
                return "[*]"
            case .counter:
                if mineCount == 0 {
                    return "   "
                }
                return "[\(String(self.mineCount))]"
            }
        }
        return "[ ]"
    }
}

struct Coord: Equatable {
    let x: Int
    let y: Int
    init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }
    static func == (lhs: Coord, rhs: Coord) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
}


enum MapError: Error {
    case posOutOfRange
}

class WorldMap: ObservableObject {
    
    var selectedCeil = [0, 0]
    @Published var worldMap: [[GameObject]]
    let worldSize: Int
    
    init(worldSize: Int = 20, mineCount: Int = 10) {
        self.worldSize = worldSize
        worldMap = Array(repeating: Array(repeating: GameObject(GameObjectType.counter), count: worldSize), count: worldSize)
        allocateMines(mineCount)
        allocateMineCounters()
    }
    
    func allocateMineCounters() {
        for x in 0...worldSize-1 {
            for y in 0...worldSize-1 {
                guard worldMap[x][y].goType != GameObjectType.mine else {
                    continue
                }
                worldMap[x][y] = GameObject(GameObjectType.counter, mineCount: countMinesAround(x, y))
            }
        }
    }
    
    func countMinesAround(_ x: Int, _ y: Int) -> Int {
        var countMines = 0
        print("START")
        for cx in x-1...x+1 {
            for cy in y-1...y+1 {
                print("\(cx):\(cy) (\(x):\(y))", terminator: " ")
                guard onMap(cx, cy) else {
                    print("our", terminator: " ")
                    continue
                }
                guard worldMap[cx][cy].goType == GameObjectType.mine else {
                    print("emp", terminator: " ")
                    continue
                }
                countMines += 1
                print("found mine", terminator: " ")
            }
            print("\n")
        }
        print("END")
        return countMines
    }
    
    func allocateMines(_ mineCount: Int) {
        for _ in (0...mineCount) {
            let mine_x = Int.random(in: 0..<worldSize)
            let mine_y = Int.random(in: 0..<worldSize)
            worldMap[mine_x][mine_y] = GameObject(GameObjectType.mine)
        }
    }
    
    func onMap(_ x: Int, _ y: Int) -> Bool {
        guard x >= 0 && y >= 0 && x < worldSize && y < worldSize else {
            return false
        }
        return true
    }
    
    func openCeil(_ x: Int, _ y: Int) {
        let go = worldMap[x][y]
        switch go.goType {
        case .mine:
            do {
                openMines()
                gameOver()
            }
        case .counter:
            if go.mineCount == 0 {
                openNearestEmpty(x, y)
            } else {
                worldMap[x][y].isOpen = true
            }
        }
    }
    
    func openMines() {
        for x in 0...worldSize-1 {
            for y in 0...worldSize-1 {
                if worldMap[x][y].goType == GameObjectType.mine {
                    worldMap[x][y].isOpen = true
                }
            }
        }
    }
    
    func gameOver() {
        print("gameOver")
    }
    
    func openNearestEmpty(_ x: Int, _ y: Int) {
        print("openNearestEmpty")
        var bfs = [Coord]()
        var visited = [Coord]()
        bfs.append(Coord(x, y))
        while !bfs.isEmpty {
            guard let cur = bfs.popLast() else {
                continue
            }
            worldMap[cur.x][cur.y].isOpen = true
            visited.append(cur)
            if worldMap[cur.x][cur.y].mineCount == 0 {
                for nx in cur.x-1...cur.x+1 {
                    for ny in cur.y-1...cur.y+1 {
                        guard onMap(nx, ny) else {
                            continue
                        }
                        let go = worldMap[nx][ny]
                        if go.goType == GameObjectType.counter {
                            let nextCoord = Coord(nx, ny)
                            if !visited.contains(nextCoord) {
                                bfs.append(nextCoord)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func pasteObject(obj: GameObject) {
        let x = self.selectedCeil[0]
        let y = self.selectedCeil[1]
        worldMap[x][y] = obj
    }
    
    func debug() {
        for objs in worldMap {
            for obj in objs {
                let icon = obj.icon(forseOpen: true)
                print("[\(icon)]", terminator: "")
            }
            print("\n")
        }
    }
}


struct ContentView: View {
    
    @ObservedObject var wm: WorldMap
    
    var body: some View {
        wm.debug()
        return VStack{
            ForEach(0..<wm.worldSize) { x in
                HStack{
                    ForEach(0..<wm.worldSize) { y in
                        let go = wm.worldMap[x][y]
                        let color = go.isOpen && go.goType == GameObjectType.mine ? Color.red : Color.black
                        Button(go.icon()) {
                            wm.openCeil(x, y)
                        } .font( .system(size: 16, weight: .thin, design: .monospaced)) .foregroundColor(color)
                            
                    }
                }
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let worldSize = 7
        let mineCount = 6
        let wm = WorldMap(worldSize: worldSize, mineCount: mineCount)
        return ContentView(
            wm: wm
        )
    }
}
