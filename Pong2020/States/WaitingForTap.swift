//
//  WaitingForTap.swift
//  Pong2020
//
//  Created by David Harrison on 28/09/2019.
//  Copyright © 2019 David Harrison. All rights reserved.
//

import SpriteKit
import GameplayKit

class WaitingForTap: GKState {
    let scene: GameScene
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        let scale = SKAction.scale(to: 1.0, duration: 0.25)
        scene.childNode(withName: "gameMessage")!.run(scale)
    }
    
    override func willExit(to nextState: GKState) {
        if nextState is Playing {
          let scale = SKAction.scale(to: 0, duration: 0.4)
          scene.childNode(withName: "gameMessage")!.run(scale)
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is Playing.Type
    }
}
