import UIKit
import Foundation
import PlaygroundSupport

class MyViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var imageView = UIImageView()
    var currentImage = UIImage()
    var infoLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Photo Flipper"
        
        self.view.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        setupSubviews()
        setupGestures()
        
        self.infoLabel.text = ""
    }
    
    func setupSubviews() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = #colorLiteral(red: 0.474509805440903, green: 0.839215695858002, blue: 0.976470589637756, alpha: 1.0)
        imageView.contentMode = .scaleAspectFit
        
        self.view.addSubview(imageView)
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.textAlignment = .center
        infoLabel.textColor = #colorLiteral(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        self.view.addSubview(infoLabel)
        
        let views = [
            "imageView": imageView,
            "orientationLabel": infoLabel
        ]
        
        let visualFormats = [
            "H:|-20-[imageView]-20-|",
            "V:|-60-[imageView]-20-|",
            "H:|-20-[orientationLabel]-20-|",
            "V:[orientationLabel]-20-|"
        ]
        
        var allConstraints = visualFormats.map { format in
            return NSLayoutConstraint.constraints(withVisualFormat: format, options: .alignAllCenterX, metrics: nil, views: views)
        }
        
        NSLayoutConstraint.activate(allConstraints.flatMap {$0} )
    }
    
    func setupGestures() {
        // open photos picker when image view is tapped once
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapImageView(sender:)))
        tap.numberOfTapsRequired = 1
        
        // we handle all 4 swipe directions: horizontally and vertically
        let swipeGestureDirections: [UISwipeGestureRecognizerDirection] = [
            .left,
            .right,
            .down,
            .up
        ] 
        
        let swipeGestures = swipeGestureDirections.map { direction -> UIGestureRecognizer in
            let gesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeImageView(sender:)))
            gesture.direction = direction
            return gesture
        }
        
        // show activity controller when double tapped
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(didDoubleTapImageView(sender:)))
        doubleTap.numberOfTapsRequired = 2
        tap.require(toFail: doubleTap)
        
        let gestures = [tap, doubleTap] + swipeGestures
        
        gestures.forEach( { (gesture) in
            self.imageView.addGestureRecognizer(gesture)
        })
        self.imageView.isUserInteractionEnabled = true
    }
    
    @objc func didTapImageView(sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            self.imageView.isUserInteractionEnabled = false
            let myPickerController = UIImagePickerController()
            myPickerController.delegate = self
            myPickerController.sourceType = .photoLibrary
            present(myPickerController, animated: true, completion: {
                self.imageView.isUserInteractionEnabled = true
            })
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.infoLabel.text = "Loading image ..."
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            picker.dismiss(animated: true, completion: { 
                self.currentImage = image
                self.imageView.image = self.currentImage
                self.infoLabel.text = ""
            })
            
        }
    }
    
    @objc func didSwipeImageView(sender: UISwipeGestureRecognizer) {
        // disable all the gestures to prevent consecutive gestures
        self.imageView.isUserInteractionEnabled = false
        self.infoLabel.text = "Flipping image ..."
        
        // perform the flipping in different queue just in case it takes 
        // time to flip the image, e.g., image is big
        let flippingQueue = DispatchQueue(label: "flipping")
        flippingQueue.async {
            let direction = sender.direction
            
            var newImage = self.currentImage
            var flipDirection: UIImageOrientation = .leftMirrored
            
            switch direction {
            case .down, .up:
                // image orientation is weird but the following seems to work
                var newOrientation: UIImageOrientation = .downMirrored
                print (self.currentImage.imageOrientation.rawValue)
                if (self.currentImage.imageOrientation == .downMirrored) {
                    newOrientation = .up
                } else if self.currentImage.imageOrientation == .upMirrored {
                    newOrientation = .down
                } else if self.currentImage.imageOrientation == .down {
                    newOrientation = .upMirrored
                }
                newImage = UIImage(cgImage: self.currentImage.cgImage!, scale: self.currentImage.scale, orientation: newOrientation)
                
            case .left, .right:
                // when swiping left or right, let's use UIKit's flipping function
                newImage = self.currentImage.withHorizontallyFlippedOrientation()
            default:
                print("Nothing")
            }
            
            DispatchQueue.main.async {
                self.currentImage = newImage
                self.imageView.image = newImage
                
                self.infoLabel.text = ""
                self.imageView.isUserInteractionEnabled = true
            }
        }
    }
    
    @objc func didDoubleTapImageView(sender: Any) {
        let activity = UIActivityViewController(activityItems: [self.currentImage], applicationActivities: nil)
        
        if activity.responds(to: "popoverPresentationController") {
            present(activity, animated: true, completion: nil)
            activity.popoverPresentationController?.sourceView = self.view
        }
    }
}

// Present the view controller in the Live View window
PlaygroundPage.current.liveView = UINavigationController(rootViewController: MyViewController())

