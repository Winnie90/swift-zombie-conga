//
//  MainMenuScene.swift
//  ZombieConga
//
//  Created by Christopher Winstanley on 03/06/2015.
//  Copyright (c) 2015 Games. All rights reserved.
//

import Foundation
import SpriteKit

class MainMenuScene : SKScene {
    override func didMoveToView(view: SKView){
        var background = SKSpriteNode(imageNamed: "MainMenu")
        background.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        self.addChild(background)
    }
    
    #if os(iOS)
        override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
            sceneTapped()
        }
    #else
    override func mouseDown(theEvent: NSEvent){
        sceneTapped()
    }
    #endif
    
    func sceneTapped(){
        let myScene = GameScene(size: self.size)
        myScene.scaleMode = self.scaleMode
        let doorway = SKTransition.doorsOpenVerticalWithDuration(1.5)
        self.view?.presentScene(myScene, transition: doorway)
    }
}