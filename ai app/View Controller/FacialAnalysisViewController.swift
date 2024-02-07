//
//  FacialAnalysisViewController.swift
//  ai app
//
//  Created by 정수경 on 2/6/24.
//

import UIKit
import Vision

class FacialAnalysisViewController: UIViewController,  UIImagePickerControllerDelegate,  UINavigationControllerDelegate {
    
    var selectedImage: UIImage?{
        didSet{
            self.blurredImageView.image = selectedImage
            self.selectedImageView.image = selectedImage
        }
    }
    
    var selectedCIImage: CIImage?{
        get{
            if let selectedImage = self.selectedImage{
                return CIImage(image: selectedImage)
            }else{
                return nil
            }
        }
    }
    
    
    @IBOutlet weak var blurredImageView: UIImageView!
    @IBOutlet weak var selectedImageView: UIImageView!

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
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
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let uiImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.selectedImage = uiImage
        }
        
        //백그라운드로 쓰레드로 처리
        DispatchQueue.main.async {
            self.detectFace()
        }
    }
     
    
    //얼굴 인식하는 펑션 - [issue] : 작업이 오래 걸리는 무거운 작업임
    func detectFace(){
        
        if let ciImage = self.selectedCIImage{
            let detectFaceRequest = VNDetectFaceRectanglesRequest(completionHandler: self.handleFaces)  //사진에서 얼굴을 찾는 펑션
            let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            
            do{
                try requestHandler.perform([detectFaceRequest])
            }catch{
                print("detectFace log : \(error)")
            }
        }
        
    }
    
    //detectFace 펑션에서 얼굴을 인식해서 handleFaces 펑션에서 받아오게 됨
    func handleFaces(request: VNRequest, error: Error?){
        if let faces = request.results as? [VNFaceObservation] {
            for face in faces{
                print("face : \(face.boundingBox)")  //바운딩 박스 : 얼굴의 좌표 위치를 알아냄 [x, y, 너비, 높이]
            }
        }
    }
    
    
}
