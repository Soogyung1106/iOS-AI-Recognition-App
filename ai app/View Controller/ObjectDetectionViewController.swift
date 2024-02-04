//
//  ObjectDetectionViewController.swift
//  ai app
//
//  Created by 정수경 on 2024/02/02.
//

import UIKit
import Vision //ML Model

class ObjectDetectionViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var selectedImageView: UIImageView!
    
    //옵저버 프로퍼티  - 이미지가 선택되었을 때를 감시
    var selectedImage: UIImage?{
        didSet{
            self.selectedImageView.image = selectedImage
        }
    }
    
    //옵저버 프로퍼티 - ciImage
    var selectedciImage: CIImage?{
        get{
            if let selectedImage = self.selectedImage{
                return CIImage(image: selectedImage)
            }else{
                return nil
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    //사진을 추가하는 펑션
    @IBAction func addPhoto(_ sender: UIBarButtonItem) {
        
        //alert actionSheet 생성
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        //1) 사진을 앨범에서 가져오는 버튼
        let importFromAlbum = UIAlertAction(title: "앨범에서 가져오기", style: .default) { _ in
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .savedPhotosAlbum
            picker.allowsEditing = true
            self.present(picker, animated: true, completion: nil)
        }
        
        //2) 사진을 찍는 버튼
        let takePhoto = UIAlertAction(title: "카메라로 찍기", style: .default) { _ in
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .camera
            picker.cameraCaptureMode = .photo
            picker.allowsEditing = true
            self.present(picker, animated: true, completion: nil)
        }
        
        //3) 취소 버튼
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        
        //actionSheet에 1)~3) 기능 추가
        actionSheet.addAction(importFromAlbum)
        actionSheet.addAction(takePhoto)
        actionSheet.addAction(cancel)
        
        //actionSheet를 보여주기
        self.present(actionSheet, animated: true, completion: nil)
        
    }
    
    
    //사용자가 이미지를 골랐을 때 작동
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        //Choose 버튼을 누른 후 앨범 화면이 내려가도록 설정
        picker.dismiss(animated: true)
        
        //Choose 버튼
        if let uiImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
            print("log : 이미지를 불러옴")
            self.selectedImage = uiImage
            self.detectObject() //사물인식 펑션 호출
        }
    }
    
    //ML 모델에 이미지를 넣어서 계산되는 부분
    func detectObject(){
        if let ciImage = self.selectedciImage{
            do{
                let vnCoreMLModel = try VNCoreMLModel(for: Inceptionv3().model)
                let request = VNCoreMLRequest(model: vnCoreMLModel, completionHandler: self.handleObjectDetection)
                request.imageCropAndScaleOption = .centerCrop
                let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
                try requestHandler.perform([request])
            }catch{
                print(error)
            }
        }
    }
    
    //ML으로 사물인식 결과를 받는 펑션
    func handleObjectDetection(request: VNRequest, error: Error?){
        //"카테고리 : 정확도" 형식으로 출력
        if let results = request.results as? [VNClassificationObservation] {
            for result in results {
                print("\(result.identifier) : \(result.confidence)")
            }
        }
    }
    
    
    

}
