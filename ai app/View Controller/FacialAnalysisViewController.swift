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
    
    let emotionsDic = [
        "Sad" : "슬픔",
        "Fear" : "두려움",
        "Happy" : "행복함",
        "Angry" : "화남",
        "Neutral" : "중립적인",
        "Surprise" : "놀람",
        "Disgust" : "혐오감"
        
    ]
    
    let genderDic = [
        "Male" : "남성",
        "Female" : "여성"
    ]
    
    
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
    
    //탭된 얼굴 이미지
    var selectedFace: UIImage?{
        //프로퍼티 옵저버
        didSet{
            if let selectedFace = self.selectedFace{
                
                //분석은 백그라운드로 작업으로 돌도록
                DispatchQueue.global(qos: .userInitiated).async {
                    self.performFaceAnalysis(on: selectedFace)
                }
            }
        }
    }
    
    
    var faceImageViews = [UIImageView]() //[issue] 얼굴 인식 후 이전 사진에서 추출된 사진이 남아있는 현상
    
    var requests = [VNRequest]() //ML 모델 3가지를 담아 놓을 배열
    
    @IBOutlet weak var blurredImageView: UIImageView!
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var facesScrollView: UIScrollView!
    
    @IBOutlet weak var genderLabel: UILabel!
    @IBOutlet weak var genderIdentifierLabel: UILabel!
    @IBOutlet weak var genderConfidenceLabel: UILabel!
    
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var ageIdentifierLabel: UILabel!
    @IBOutlet weak var ageConfidenceLabel: UILabel!
    
    @IBOutlet weak var emotionLabel: UILabel!
    @IBOutlet weak var emotionIdentifierLabel: UILabel!
    @IBOutlet weak var emotionConfidenceLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideAllLabels() //[issue 해결] 처음 화면에 로딩되었을 때도 라벨들이 보임
        
        do{
            let genderModel = try VNCoreMLModel(for: GenderNet().model)
            self.requests.append(VNCoreMLRequest(model: genderModel, completionHandler: handleGenderClassification))
            
            let ageModel = try VNCoreMLModel(for: AgeNet().model)
            self.requests.append(VNCoreMLRequest(model: ageModel, completionHandler: handleAgeClassification))
            
            let emotionModel = try VNCoreMLModel(for: CNNEmotions().model)
            self.requests.append(VNCoreMLRequest(model: emotionModel, completionHandler: handleEmotionClassification))
            
        }catch {
            print("viewDidLoad() log : \(error)")
        }
        
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
            self.hideAllLabels() //[issue 해결] 새로운 이미지가 선택되면 기존 라벨 숨김
            
            
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
                print("detectFaces() log : \(error)")
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
                    
                    //각각의 얼굴 선택시 인터렉션 추가
                    faceImageView.isUserInteractionEnabled = true
                    
                    
                    //UITapGestureRecognizer - 이미지에 탭 액션이 발생했을 때 이벤트를 알려주는 클래스
                    //이미지 탭했을 때 handleFaceImageViewTap 펑션을 호출
                    let tap = UITapGestureRecognizer(target: self, action: #selector(FacialAnalysisViewController.handleFaceImageViewTap(_:)))
                    faceImageView.addGestureRecognizer(tap)
                    
                    
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
    
    //이미지 탭했을 때 호출되는 펑션
    //@objc - Object-C와 Swift와의 호환성을 위해 추가된 문법
    @objc func handleFaceImageViewTap(_ sender: UITapGestureRecognizer){
        //탭이 된 이미지는 파란색으로 ui 표시
        if let tappedImageView = sender.view as? UIImageView{
            
            //선택된 단 하나의 이미지만 표시하도록 나머지들은 ui 제거
            for faceImageView in faceImageViews {
                faceImageView.layer.borderWidth = 0
                faceImageView.layer.borderColor = UIColor.clear.cgColor
            }
            
            tappedImageView.layer.borderWidth = 3
            tappedImageView.layer.borderColor = UIColor.blue.cgColor
            
            self.selectedFace = tappedImageView.image
        }
    }
    
    //얼굴을 분석하는 펑션
    func performFaceAnalysis(on image: UIImage){
        do{
            for request in requests {
                let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
                try handler.perform([request])
            }
        }catch{
            print("performFaceAnalysis() log : \(error)")
        }
    }
                                 
    func handleGenderClassification(request: VNRequest, error: Error?){
        if let genderObservation = request.results?.first as? VNClassificationObservation{
            //print("gender : \(genderObservation.identifier), confidence : \(genderObservation.confidence)")
            
            //UI적 요소는 메인 쓰레드에서 호출
            DispatchQueue.main.async {
                self.genderIdentifierLabel.text = self.genderDic[genderObservation.identifier] //En -> Ko
                self.genderConfidenceLabel.text = "\(String(format: "%.2f", genderObservation.confidence*100))%"
                self.showGenderLabels()
            }
        }
    }
    
    func handleAgeClassification(request: VNRequest, error: Error?){
        if let ageObservation = request.results?.first as? VNClassificationObservation{
            //print("age : \(ageObservation.identifier), confidence : \(ageObservation.confidence)")
            
            DispatchQueue.main.async {
                self.ageIdentifierLabel.text = ageObservation.identifier
                self.ageConfidenceLabel.text = "\(String(format: "%.2f", ageObservation.confidence*100))%"
                self.showAgeLabels()
            }
        }
    }
    
    func handleEmotionClassification(request: VNRequest, error: Error?){
        if let emotionObservation = request.results?.first as? VNClassificationObservation{
            //print("emotion : \(emotionObservation.identifier), confidence : \(emotionObservation.confidence)")
            
            DispatchQueue.main.async {
                self.emotionIdentifierLabel.text = self.emotionsDic[emotionObservation.identifier]  //En -> Ko
                self.emotionConfidenceLabel.text = "\(String(format: "%.2f", emotionObservation.confidence*100))%"
                self.showEmotionLabels()
            }
        }
        
    }
    
    //라벨을 다 숨기는 펑션
    func hideAllLabels(){
        self.genderLabel.isHidden = true
        self.genderIdentifierLabel.isHidden = true
        self.genderConfidenceLabel.isHidden = true
        
        self.ageLabel.isHidden = true
        self.ageIdentifierLabel.isHidden = true
        self.ageConfidenceLabel.isHidden = true
        
        self.emotionLabel.isHidden = true
        self.emotionIdentifierLabel.isHidden = true
        self.emotionConfidenceLabel.isHidden = true
        
        
    }
    
    //분석 후 숨겼던 라벨을 다시 보여주는 펑션
    func showGenderLabels(){
        self.genderLabel.isHidden = false
        self.genderIdentifierLabel.isHidden = false
        self.genderConfidenceLabel.isHidden = false
    }
    
    
    func showAgeLabels(){
        self.ageLabel.isHidden = false
        self.ageIdentifierLabel.isHidden = false
        self.ageConfidenceLabel.isHidden = false
    }
    
    func showEmotionLabels(){
        self.emotionLabel.isHidden = false
        self.emotionIdentifierLabel.isHidden = false
        self.emotionConfidenceLabel.isHidden = false
    }
    
}
