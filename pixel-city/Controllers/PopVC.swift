//
//  PopVC.swift
//  pixel-city
//
//  Created by Ahmed Mohamed El-Desouky on 12/7/18.
//  Copyright © 2018 Ahmed Mohamed El-Desouky. All rights reserved.
//

import UIKit

class PopVC: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var popImg: UIImageView!
    
    var passedImage: UIImage!
    
    func initData(forImage image: UIImage) {
        self.passedImage = image
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        popImg.image = passedImage
        addDoubleTap()
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(screenWasDoubleTapped))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        view.addGestureRecognizer(doubleTap)
    }
    @objc func screenWasDoubleTapped() {
        dismiss(animated: true, completion: nil)
    }
}
