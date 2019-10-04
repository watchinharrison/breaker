//
//  GameOver.swift
//  Pong2020
//
//  Created by David Harrison on 28/09/2019.
//  Copyright © 2019 David Harrison. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameOver: GKState {
    let scene: GameScene
    
    init(scene: SKScene) {
        self.scene = scene as! GameScene
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        if previousState is Playing {
        }
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass is WaitingForTap.Type
    }
}
