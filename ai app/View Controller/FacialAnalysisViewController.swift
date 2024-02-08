//
//  FacialAnalysisViewController.swift
//  ai app
//
//  Created by 정수경 on 2/6/24.
//

import UIKit
import Vision
import AVFoundation

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
    
    var faceImageViews = [UIImageView]() //[issue] 얼굴 인식 후 이전 사진에서 추출된 사진이 남아있는 현상
    
    @IBOutlet weak var blurredImageView: UIImageView!
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var facesScrollView: UIScrollView!
    
    
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
            self.removeRectangles()  //[issue 해결] 이미지를 새로 고를때마다 이전 프레임들 삭제
            self.removeFaceImageViews() //[issue 해결] 이미지를 새로 고를때마다 이전에 인식됬던 얼굴 삭제
            
            DispatchQueue.global(qos: .userInitiated).async{
                self.detectFaces()
            }
        }
        
        //백그라운드로 쓰레드로 처리
//        DispatchQueue.main.async {
//            self.detectFaces()
//        }
    }
     
    
    //얼굴 인식하는 펑션 - [issue] : 작업이 오래 걸리는 무거운 작업임
    func detectFaces(){
        
        if let ciImage = self.selectedCIImage{
            let detectFaceRequest = VNDetectFaceRectanglesRequest(completionHandler: self.handleFaces)  //사진에서 얼굴을 찾는 펑션
            let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            
            do{
                try requestHandler.perform([detectFaceRequest])
            }catch{
                print("detectFaces log : \(error)")
            }
        }
        
    }
    
    //detectFaces 펑션에서 얼굴을 인식해서 handleFaces 펑션에서 받아오게 됨
    func handleFaces(request: VNRequest, error: Error?){
        if let faces = request.results as? [VNFaceObservation] {
//            for face in faces{
//                print("face : \(face.boundingBox)")  //바운딩 박스 : 얼굴의 좌표 위치를 알아냄 [x, y, 너비, 높이]
//            }
            
            //UI는 메인 쓰레드에서 작동
            DispatchQueue.main.async {
                self.displayUI(for: faces)
            }
        }
    }
    
    //사진에서 찾은 얼굴에 직사각형을 표시해주는 UI 펑션
    func displayUI(for faces: [VNFaceObservation]){
        if let faceImage = self.selectedImage{
            let imageRect = AVMakeRect(aspectRatio: faceImage.size, insideRect: self.selectedImageView.bounds)
            
            //사진에 얼굴이 여러개인 경우 for 루프를 돈다.
            for (index, face) in faces.enumerated(){
                
                //UIImageView - 상단
                let w = face.boundingBox.size.width * imageRect.width //원본사진의 가로 : 세로 = 1 : 1, width는 비율
                let h = face.boundingBox.size.height * imageRect.height
                let x = face.boundingBox.origin.x * imageRect.width
                let y = imageRect.maxY - (face.boundingBox.origin.y * imageRect.height) - h
                
                //얼굴 인식 프레임 속성
                let layer = CAShapeLayer()
                layer.frame = CGRect(x: x, y: y, width: w, height: h) //프레임 좌표 전달
                layer.borderColor = UIColor.red.cgColor //선의 색상
                layer.borderWidth = 1 //두께
                self.selectedImageView.layer.addSublayer(layer)
                
                
                //Scroll View - 하단
                let w2 = face.boundingBox.size.width * faceImage.size.width //원본사진의 가로 : 세로 = 1 : 1, width는 비율
                let h2 = face.boundingBox.size.height * faceImage.size.height
                let x2 = face.boundingBox.origin.x * faceImage.size.width
                let y2 = (1 - face.boundingBox.origin.y) * faceImage.size.height - h2
                let cropRect = CGRect(x: x2 * faceImage.scale, y: y2 * faceImage.scale, width: w2 * faceImage.scale, height: h2 * faceImage.scale)
                
                if let faceCgImage = faceImage.cgImage?.cropping(to: cropRect){
                    let faceUiImage = UIImage(cgImage: faceCgImage, scale: faceImage.scale, orientation: .up)
                    let faceImageView = UIImageView(frame:  CGRect(x: 90 * index , y: 0, width: 80, height: 80))  //x의 위치는 얼굴이 여러개일 경우 시작점이 인덱스에 따라 바뀌게 된다. / 사진별 간격 10
                    faceImageView.image = faceUiImage
                    self.facesScrollView.addSubview(faceImageView) //얼굴마다 서브뷰를 스크롤뷰 리스트에 추가
                    self.faceImageViews.append(faceImageView)  //배열에 인식된 얼굴들 추가
                }
                
                self.facesScrollView.contentSize = CGSize(width: 90 * faces.count - 10, height: 80) //마지막 사진 뒤의 10 간격은 삭제
                
            }
        }
    }
    
    //[issue 해결] 새로운 사진을 불러올 때, 이전에 인식했던 얼굴 frame 남아있음
    func removeRectangles(){
        if let sublayers = self.selectedImageView.layer.sublayers{
            for layer in sublayers{
                layer.removeFromSuperlayer()
            }
        }
    }
    
    //[issue 해결] 얼굴 인식 후 이전 사진에서 추출된 사진이 남아있는 현상
    func removeFaceImageViews(){
        for faceImageView in faceImageViews {
            faceImageView.removeFromSuperview()
        }
        
        self.faceImageViews.removeAll()
    }
    
    
    
}
