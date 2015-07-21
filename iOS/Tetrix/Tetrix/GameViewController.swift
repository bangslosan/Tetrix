//
//  GameViewController.swift
//  Tetrix
//
//  Created by Leonardo Cardoso on 7/20/15.
//  Copyright (c) 2015 leocardz. All rights reserved.
//

import UIKit
import SpriteKit

extension SKNode {
    class func unarchiveFromFile(file : String) -> SKNode? {
        if let path = NSBundle.mainBundle().pathForResource(file, ofType: "sks") {
            var sceneData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)!
            var archiver = NSKeyedUnarchiver(forReadingWithData: sceneData)
            
            archiver.setClass(self.classForKeyedUnarchiver(), forClassName: "SKScene")
            let scene = archiver.decodeObjectForKey(NSKeyedArchiveRootObjectKey) as! GameScene
            archiver.finishDecoding()
            return scene
        } else {
            return nil
        }
    }
}

class GameViewController: UIViewController, TetrixDelegate, UIGestureRecognizerDelegate {
    
    var scene: GameScene!
    var tetrix: Tetrix!
    
    @IBOutlet var scoreLabel: UILabel!
    @IBOutlet var levelLabel: UILabel!
    @IBOutlet var recordLabel: UILabel!
    
    
    var panPointReference:CGPoint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the view.
        let skView = view as! SKView
        skView.multipleTouchEnabled = false
        
        // Create and configure the scene.
        scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .AspectFill
        
        scene.tick = didTick
        
        tetrix = Tetrix()
        tetrix.delegate = self
        tetrix.beginGame()
        
        // Present the scene.
        skView.presentScene(scene)
        
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    @IBAction func didTap(sender: UITapGestureRecognizer) {
        tetrix.rotateShape()
    }
    
    func didTick() {
        tetrix.letShapeFall()
    }
    
    @IBAction func didPan(sender: UIPanGestureRecognizer) {
        
        let currentPoint = sender.translationInView(self.view)
        if let originalPoint = panPointReference {
            
            if abs(currentPoint.x - originalPoint.x) > (BlockSize * 0.9) {
                
                if sender.velocityInView(self.view).x > CGFloat(0) {
                    tetrix.moveShapeRight()
                    panPointReference = currentPoint
                } else {
                    tetrix.moveShapeLeft()
                    panPointReference = currentPoint
                }
            }
        } else if sender.state == .Began {
            panPointReference = currentPoint
        }
    }
    
    @IBAction func didSwipe(sender: UISwipeGestureRecognizer) {
        tetrix.dropShape()
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if let swipeRec = gestureRecognizer as? UISwipeGestureRecognizer {
            if let panRec = otherGestureRecognizer as? UIPanGestureRecognizer {
                return true
            }
        } else if let panRec = gestureRecognizer as? UIPanGestureRecognizer {
            if let tapRec = otherGestureRecognizer as? UITapGestureRecognizer {
                return true
            }
        }
        return false
    }
    
    func nextShape() {
        let newShapes = tetrix.newShape()
        if let fallingShape = newShapes.fallingShape {
            self.scene.addPreviewShapeToScene(newShapes.nextShape!) {}
            self.scene.movePreviewShape(fallingShape) {
                
                self.view.userInteractionEnabled = true
                self.scene.startTicking()
            }
        }
    }
    
    func gameDidBegin(tetrix: Tetrix) {
        
        levelLabel.text = "\(tetrix.level)"
        scoreLabel.text = "\(tetrix.score)"
        scene.tickLengthMillis = TickLengthLevelOne
        
        // The following is false when restarting a new game
        if tetrix.nextShape != nil && tetrix.nextShape!.blocks[0].sprite == nil {
            scene.addPreviewShapeToScene(tetrix.nextShape!) {
                self.nextShape()
            }
        } else {
            nextShape()
        }
    }
    
    func gameDidEnd(tetrix: Tetrix) {
        view.userInteractionEnabled = false
        scene.stopTicking()
        
        scene.playSound("gameover.mp3")
        scene.animateCollapsingLines(tetrix.removeAllBlocks(), fallenBlocks: Array<Array<Block>>()) {
            tetrix.beginGame()
        }
    }
    
    func gameDidLevelUp(tetrix: Tetrix) {
        levelLabel.text = "\(tetrix.level)"
        if scene.tickLengthMillis >= 100 {
            scene.tickLengthMillis -= 100
        } else if scene.tickLengthMillis > 50 {
            scene.tickLengthMillis -= 50
        }
        scene.playSound("levelup.mp3")
    }
    
    func gameShapeDidDrop(tetrix: Tetrix) {
        scene.stopTicking()
        scene.redrawShape(tetrix.fallingShape!) {
            tetrix.letShapeFall()
        }
        scene.playSound("drop.mp3")
    }
    
    func gameShapeDidLand(tetrix: Tetrix) {
        scene.stopTicking()
        self.view.userInteractionEnabled = false
        
        let removedLines = tetrix.removeCompletedLines()
        if removedLines.linesRemoved.count > 0 {
            self.scoreLabel.text = "\(tetrix.score)"
            scene.animateCollapsingLines(removedLines.linesRemoved, fallenBlocks:removedLines.fallenBlocks) {
                
                self.gameShapeDidLand(tetrix)
            }
            scene.playSound("bomb.mp3")
        } else {
            nextShape()
        }
    }
    
    func gameShapeDidMove(tetrix: Tetrix) {
        scene.redrawShape(tetrix.fallingShape!) {}
    }
}