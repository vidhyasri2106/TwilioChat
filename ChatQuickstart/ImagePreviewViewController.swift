//
//  ImagePreviewViewController.swift
//  ChatQuickstart
//
//  Created by Vidhya Sri Soundararajan on 26/02/19.
//  Copyright © 2019 Twilio, Inc. All rights reserved.
//

import UIKit

protocol ImageSelectionDelegate {
    func imageSelected(pickedImage: UIImage)
}

class ImagePreviewViewController: UIViewController {
    @IBOutlet weak var previewImage: UIImageView!
    var pickedImage: UIImage!
    var imageDelegate: ImageSelectionDelegate!

    override func viewDidLoad() {
        previewImage.image = pickedImage
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func sendAction(_ sender: Any) {
        imageDelegate.imageSelected(pickedImage: previewImage.image!)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
