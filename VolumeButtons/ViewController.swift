//
//  ViewController.swift
//  VolumeButtons
//
//  Created by Christian Mittendorf on 05/08/16.
//  Copyright © 2016 Christian Mittendorf. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    enum VolumeButtonAction {
        case up, down

        var title: String {
            switch self {
            case .up:
                return "👍"
            case .down:
                return "👎"
            }
        }
    }

    @IBOutlet weak var infoLabel: UILabel!

    let volumeButtonHandler = VolumeButtonHandler()

    override func viewDidLoad() {
        super.viewDidLoad()

        infoLabel.text = nil

        volumeButtonHandler.volumeUpAction = {
            self.volumeButtonPressed(action: .up)
        }

        volumeButtonHandler.volumeDownAction = {
            self.volumeButtonPressed(action: .down)
        }
    }

    func volumeButtonPressed(action: VolumeButtonAction) {
        self.setLabel(text: action.title)
        self.view.backgroundColor = .randomColor()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() +
            DispatchTimeInterval.milliseconds(2000)) {
                self.setLabel(text: nil)
        }
    }

    func setLabel(text: String?) {
        let transition = CATransition()
        transition.duration = 0.35
        transition.timingFunction =
            CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transition.type = kCATransitionFade
        self.infoLabel.layer.add(transition, forKey: nil)
        self.infoLabel.text = text
    }
}

extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

extension UIColor {
    static func randomColor() -> UIColor {
        return UIColor(red: .random(),
                       green: .random(),
                       blue: .random(),
                       alpha: 1.0)
    }
}
