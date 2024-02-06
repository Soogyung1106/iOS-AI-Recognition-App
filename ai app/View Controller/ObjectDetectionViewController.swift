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
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    
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
        
        //첫 화면에서 보이는 라벨 초기화
        self.activityIndicatorView.hidesWhenStopped = true
        self.activityIndicatorView.stopAnimating()
        self.categoryLabel.text = ""
        self.confidenceLabel.text = ""
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
            
            //이미지가 선택되면 로딩 아이콘 설정 - activityIndicatorView
            self.activityIndicatorView.startAnimating()
            self.categoryLabel.text = ""
            self.confidenceLabel.text = ""
            
            
            //[issue 해결] 싱글 쓰레드에서 멀티쓰레드 호출로 방식 변경
            DispatchQueue.global(qos: .userInitiated).async {
                self.detectObject() //사물인식 펑션 호출
            }
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
                try requestHandler.perform([request])   //[issue] 작업이 오래 걸리는 펑션 -> 사진에 따라서 앱 로딩 시간 길어지는 freeze 현상
            }catch{
                print(error)
            }
        }
    }
    
    //ML으로 사물인식 결과를 받는 펑션
    func handleObjectDetection(request: VNRequest, error: Error?){
        //"카테고리 : 정확도" 형식으로 출력
//        if let results = request.results as? [VNClassificationObservation] {
//            for result in results {
//                print("log : \(result.identifier) : \(result.confidence)")
//            }
//        }
        
        //화면에 표시 - Label
        if let result = request.results?.first as? VNClassificationObservation {
            
            //UI적인 부분은 반드시 메인 쓰레드에서 실행되야 함
            DispatchQueue.main.async {
                self.activityIndicatorView.stopAnimating()  //분석이 완료되면 로딩 아이콘 중지 - activityIndicatorView 
                self.categoryLabel.text = result.identifier    //카테고리
    //            self.confidenceLabel.text = "\(result.confidence)"  //정확도
                self.confidenceLabel.text = "\(String(format: "%.2f", result.confidence*100))%"  //사용자 친화적으로 정확도 수치 변경

            }
        }
        
    }
     
}

