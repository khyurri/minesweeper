//
//  minesweeperApp.swift
//  minesweeper
//
//  Created by Ruslan Khyurri on 2/17/22.
//

import SwiftUI

let worldSize = 7
let mineCount = 6
let wm = WorldMap(worldSize: worldSize, mineCount: mineCount)

@main
struct minesweeperApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                wm: wm
            )
        }
    }
}
