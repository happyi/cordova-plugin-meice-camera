import UIKit
import MCCamera
import MCCameraUI
import AVKit

// 先在Info.plist设置Allow Arbitrary Loads为YES
protocol MCUIDelegate:NSObjectProtocol{
    
    func uploadSuccess(result:Dictionary<String,Any>)
    
    func handelError(errMsg:String)
}
class MyClick:UITapGestureRecognizer{
    var index:Int = 0
}

class CustomerMCCarmeraUI: UIViewController {
    
    weak var delegate: MCUIDelegate?
    var ble:MCBLE = MCBLE()
    var previewView:MCCameraPreviewView = MCCameraPreviewView()
    let closeBtn = UIImageView(image:UIImage.init(named: "back.png"))
    let backLabel = UILabel()
    let titleLabel = UILabel()
    let imgView:UIImageView = UIImageView()
    var camera:MCCamera = MCCamera()
    var params:[String : String]?
    let checked:UIColor =  UIColor(red: 0.2, green: 0.73, blue: 0.77, alpha: 1)
    let unchecked:UIColor =   UIColor(red: 0.42, green: 0.42, blue: 0.42,alpha:1)
    
    var interfaceOrientations:UIInterfaceOrientationMask = .portrait{
        didSet{
            if interfaceOrientations == .portrait{
                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue,
                                          forKey: "orientation")
            }
        }
    }
    let shootBtn = UIImageView(image:UIImage.init(named: "caramera.png"))
    let activity = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.whiteLarge)
    let label:UILabel = UILabel()
    var ScreenWidth = UIScreen.main.bounds.width
    var ScreenHeight = UIScreen.main.bounds.height
    let statusBar = UIApplication.shared.statusBarFrame.size.height
    var current = 0
    var end = 4
    var prepared = false
    var auto = false
    //    var luminance = [73,90,100,158,153]
    var luminance = [160,160,160,255,255]
    var step = 0
    let steps = ["左脸","右脸","正脸"]
    let lights = ["日光","交叉","平行","UV","伍德"]
    var imgData = [Data]()
    var leftImg:UIImage?
    var rightImg:UIImage?
    var audioPlayer:AVPlayer?=nil
    var playerItem:AVPlayerItem?
    var initPlay = false
    var playing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 1. 设置导航栏不透明
        navigationController?.navigationBar.isTranslucent = false
        if ScreenWidth > ScreenHeight{
            let temp = ScreenHeight
            self.ScreenHeight = self.ScreenWidth
            self.ScreenWidth = temp
        }
        print("ScreenWidth:\(ScreenWidth),ScreenHeight:\(ScreenHeight)")
        self.previewView.frame = CGRect(x: 0, y: -64, width: ScreenWidth, height: ScreenHeight)
        self.view.addSubview(previewView)
        //loading
        self.activity.frame = CGRect(x: ScreenWidth/2-50, y: ScreenHeight/2-50, width: 100, height: 100)
        self.activity.backgroundColor = UIColor.gray
        self.activity.layer.masksToBounds = true
        self.activity.layer.cornerRadius = 6.0
        self.activity.layer.borderWidth = 1.0
        self.activity.layer.borderColor = UIColor.gray.cgColor
        self.view.addSubview(self.activity)
        
        self.label.text = "蓝牙连接中"
        self.label.frame = CGRect(x: ScreenWidth/2-50, y: ScreenHeight/2-100, width: 100, height: 30)
        self.label.textAlignment = NSTextAlignment.center
        self.label.textColor = UIColor.white
        self.view.addSubview(self.label)
        
        self.shootBtn.isUserInteractionEnabled = true
        self.shootBtn.isHidden = true
        self.shootBtn.addGestureRecognizer(MyClick(target: self, action: #selector(clickShoot)))
        self.shootBtn.frame = CGRect(x:ScreenWidth/2-50, y: ScreenHeight-200, width: 100, height: 100)
        self.previewView.addSubview(self.shootBtn)
        //close
        
        self.closeBtn.isUserInteractionEnabled = true
        self.closeBtn.addGestureRecognizer(MyClick(target: self, action: #selector(closeBtnClick)))
        self.closeBtn.frame = CGRect(x:10, y: statusBar+20, width: 30, height: 30)
        self.view.addSubview(closeBtn)
        self.view.bringSubviewToFront(self.closeBtn)
        
        self.backLabel.text = "返回"
        self.backLabel.isUserInteractionEnabled = true
        self.backLabel.addGestureRecognizer(MyClick(target: self, action: #selector(closeBtnClick)))
        self.backLabel.frame = CGRect(x: 50, y: statusBar+20, width: 40, height: 30)
        self.backLabel.textAlignment = NSTextAlignment.center
        self.backLabel.textColor = UIColor.white
        self.view.addSubview(backLabel)
        self.view.bringSubviewToFront(self.backLabel)
        
        self.titleLabel.text = "请拍摄左脸"
        self.titleLabel.frame = CGRect(x: ScreenWidth/2-100, y: statusBar+20, width: 200, height: 30)
        self.titleLabel.textAlignment = NSTextAlignment.center
        self.titleLabel.textColor = UIColor.white
        self.view.addSubview(titleLabel)
        self.view.bringSubviewToFront(self.titleLabel)
        
        self.imgView.frame = CGRect(x: 0, y: -64, width: ScreenWidth, height: ScreenHeight+64)
        
        self.activity.startAnimating()
     
        camera.setup(successBlock: { [unowned self] in
            self.ble.setup()
            self.ble.delegate = self
            self.ble.startScan()
            
            DispatchQueue.main.async {
                self.previewView.videoPreviewLayer.session = self.camera.session
                self.previewView.videoPreviewLayer.videoGravity = .resizeAspect
            }
            }, failureBlock: {
                print("error")
        })
        camera.delegate = self
        
        self.initPlay = true
        self.playing = true
        let urlPath = Bundle.main.url(forResource: "init.mp3", withExtension: nil)
        self.playerItem = AVPlayerItem(url: urlPath!)
        self.audioPlayer =  AVPlayer(playerItem: playerItem!)
        self.audioPlayer?.volume = 1.0
        self.audioPlayer?.play()
        
    }
    @objc func finishedPlaying(myNotification:NSNotification) {
        self.playing = false
        if self.initPlay  {
            if self.step == 0{
                self.prepareLight(index:0)
            }
            self.initPlay = false
        }
    }
    func prepareLight(index:Int)
    {
        print("prepareLight:\(index)")
        if self.step == 0
        {
            if(!self.playing)
            {
                let urlPath = Bundle.main.url(forResource: "left.mp3", withExtension: nil)
                self.playerItem = AVPlayerItem(url: urlPath!)
                self.audioPlayer =  AVPlayer(playerItem: playerItem!)
                self.audioPlayer?.volume = 1.0
                self.audioPlayer?.play()
            }
            self.titleLabel.text = "请拍摄左脸"
            self.view.bringSubviewToFront(self.titleLabel)
        }
        if self.step == 1
        {
            if(!self.playing)
            {
                let urlPath = Bundle.main.url(forResource: "right.mp3", withExtension: nil)
                self.playerItem = AVPlayerItem(url: urlPath!)
                self.audioPlayer =  AVPlayer(playerItem: playerItem!)
                self.audioPlayer?.volume = 1.0
                self.audioPlayer?.play()
            }
            self.titleLabel.text = "请拍摄右脸"
            self.view.bringSubviewToFront(self.titleLabel)
        }
        if self.step == 2
        {
            if(!self.playing && index == 0 &&  !self.auto)
            {
                let urlPath = Bundle.main.url(forResource: "mid.mp3", withExtension: nil)
                self.playerItem = AVPlayerItem(url: urlPath!)
                self.audioPlayer =  AVPlayer(playerItem: playerItem!)
                self.audioPlayer?.volume = 1.0
                self.audioPlayer?.play()
                self.titleLabel.text = "请拍摄正脸(共5张)"
                self.view.bringSubviewToFront(self.titleLabel)
            }
        }
        if !auto {
            self.shootBtn.isHidden = false
        }
        self.prepared = false
        self.current = index
        self.drawLight(lightIndex: index)
        self.ble.lightupAt(index, value: luminance[index])
        self.camera.configCamera(forLight: index, iPad: "iPad")
        //        self.camera.focusAt(point: previewView.center, inView: previewView)
        
        self.prepared = true
    }
    
    @objc func closeBtnClick(){
        
        let alertController =  UIAlertController(title: "通知", message: "确定要退出吗？", preferredStyle: UIAlertController.Style.alert)
        let confirmAction = UIAlertAction(title: "确定", style: UIAlertAction.Style.default) { (UIAlertAction) -> Void in
            
            print("确定按钮点击事件")
            self.camera.session?.stopRunning()
            self.dismiss(animated: true, completion:nil)
        }
        
        let cancleAction = UIAlertAction(title: "取消", style: UIAlertAction.Style.default) { (UIAlertAction) -> Void in
            
            print("取消按钮点击事件")
            
        }
        alertController.addAction(confirmAction)
        alertController.addAction(cancleAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func clickShoot(){
        
        self.shootBtn.isHidden = true
        if self.step == 2 {
            self.auto = true
            self.titleLabel.text = "自动拍摄中,请稍后"
            self.view.bringSubviewToFront(self.titleLabel)
            self.prepareLight(index: 0)
            self.camera.focusAt(point: previewView.center, inView: previewView)
            //            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            //                self.camera.capture(forLight: self.current)
            //            }
        }else{
            self.ble.lightupAt(0, value: luminance[0])
            self.camera.configCamera(forLight: 0, iPad: "iPad")
            self.camera.focusAt(point: previewView.center, inView: previewView)
            
            DispatchQueue.main.asyncAfter(deadline:.now()+3.5) {
                self.camera.capture(forLight: 0);
            }
        }
    }
    @objc func viewClick(sender:MyClick){
        print("viewClick:\(sender.index)")
        self.drawPreiview(index: sender.index)
        
    }
    @objc func resetBtnClick(){
        
        self.imgData = [Data]()
        self.imgView.removeFromSuperview()
        self.previewView.isHidden = false
        self.camera.session?.startRunning()
        self.shootBtn.isHidden = false
        if self.step == 2
        {
            self.auto = true
        }else{
            self.auto = false
        }
        
        self.prepareLight(index: 0)
        
    }
    @objc func nextBtnClick(){
        
        self.step = self.step + 1
        self.imgView.removeFromSuperview()
        self.previewView.isHidden = false
        self.camera.session?.startRunning()
        self.shootBtn.isHidden = false
        self.prepareLight(index: 0)
        
    }
    
    var processing = false
    
    @objc func uploadBtnClick(){
        if self.processing {
            return
        }
        self.processing = true
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.frame = CGRect(x: 100, y: ScreenHeight/2-10, width: ScreenWidth-200, height: 10)
        progressView.transform = CGAffineTransform(scaleX: 1.0, y: 5.0)
        
        self.imgView.addSubview(progressView)
        let progressLable:UILabel = UILabel()
        progressLable.frame =  CGRect(x: 100, y: ScreenHeight/2+20, width: ScreenWidth-200, height: 10)
        progressLable.textAlignment = NSTextAlignment.center
        progressLable.textColor = UIColor.white
        self.imgView.addSubview(progressLable)
        
        MCApi.upload(datas: self.imgData, progressBlock: { (data) in
            
            if data == 1{
                
                progressLable.text = "分析中这个过程几秒到几分钟请耐心等待"
                
            }else{
                let text =  String(format:"%.2f",data*100)
                progressLable.text = "图片上传中：进度\(text)%"
            }
            progressView.progress = Float(data)
            progressView.progressTintColor = UIColor.green //进度颜色
            progressView.trackTintColor = UIColor.gray //剩余进度颜色
        }, successBlock: { (response) in
            progressLable.text = "报告已经生成"
            self.processing = false
            
            do{
                let leftImgPath = NSHomeDirectory().appending("/Documents/").appending("leftImg.jpg")
                let leftImg = self.leftImg?.jpegData(compressionQuality: 0.7)?.base64EncodedString()
                let data = self.leftImg?.jpegData(compressionQuality: 0.7)
                try data?.write(to:  URL.init(fileURLWithPath: leftImgPath))
                
                let rightImgPath = NSHomeDirectory().appending("/Documents/").appending("rightImg.jpg")
                let rightImg = self.rightImg?.jpegData(compressionQuality: 0.7)?.base64EncodedString()
                let data2 = self.leftImg?.jpegData(compressionQuality: 0.7)
                try data2?.write(to:  URL.init(fileURLWithPath: rightImgPath))
                
                let result:Dictionary<String,Any> = ["customerPicId":response,
                                                     "leftImgPath":leftImgPath as Any,
                                                     "leftImg":leftImg as Any,
                                                     "rightImgPath":rightImgPath as Any,
                                                     "rightImg":rightImg as Any
                ]
                self.delegate?.uploadSuccess(result: result)
            }catch let error {
                print("Img save error \(error)")
                self.delegate?.handelError(errMsg: "Img save error \(error)")
            }
            
        }) { (code, message) in
            self.processing = false
            self.delegate?.handelError(errMsg: "code:\(code),message:\(message)")
        }
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        
        NotificationCenter.default.addObserver(self, selector: #selector(finishedPlaying),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.playerItem)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //        UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
        
        NotificationCenter.default.removeObserver(self)
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    override var prefersStatusBarHidden: Bool{
        return false
    }
}
extension CustomerMCCarmeraUI{
    func drawPreiview(index:Int){
        
        if self.view.viewWithTag(900) == nil{
            self.imgView.isUserInteractionEnabled = true
            self.view.addSubview(self.imgView)
            self.view.bringSubviewToFront(self.backLabel)
            self.view.bringSubviewToFront(self.closeBtn)
        }
        if self.step == 0 {
            self.imgView.image = UIImage.init(data: (self.leftImg?.jpegData(compressionQuality: 0.7))!);
        }
        if self.step == 1 {
            self.imgView.image = UIImage.init(data: (self.rightImg?.jpegData(compressionQuality: 0.7))!);
        }
        if self.step == 2{
            self.imgView.image = UIImage.init(data: self.imgData[index]);
            self.titleLabel.text = "拍摄完成"
            self.view.bringSubviewToFront(self.titleLabel)
            
            if  !self.playing {
                self.playing = true
                let urlPath = Bundle.main.url(forResource: "finished.mp3", withExtension: nil)
                self.playerItem = AVPlayerItem(url: urlPath!)
                self.audioPlayer =  AVPlayer(playerItem: playerItem!)
                self.audioPlayer?.volume = 1.0
                self.audioPlayer?.play()
            }
            
        }
        //        self.current = index
        
        if self.imgView.viewWithTag(900) == nil{
            let layerView = UIView()
            layerView.tag = 900
            layerView.frame = CGRect(x: 0, y: ScreenHeight-40, width: ScreenWidth, height: 104)
            // layerFillCode
            let layer = CALayer()
            layer.frame = layerView.bounds
            layer.backgroundColor = UIColor(red: 0.1, green: 0.09, blue: 0.09, alpha: 1).cgColor
            layerView.layer.addSublayer(layer)
            self.imgView.addSubview(layerView)
        }
        var tag = 901
        if self.view.viewWithTag(tag) == nil{
            let resetBtn = UIImageView(image:UIImage.init(named: "reset.png"))
            resetBtn.tag = tag
            resetBtn.isUserInteractionEnabled = true
            resetBtn.addGestureRecognizer(MyClick(target: self, action: #selector(resetBtnClick)))
            resetBtn.frame = CGRect(x:251, y: ScreenHeight-10, width: 111, height: 48)
            self.imgView.addSubview(resetBtn)
        }
        
        tag = 902
        if self.view.viewWithTag(tag) == nil {
            if self.step == 0 || self.step == 1  {
                let confirmBtn = UIImageView(image:UIImage.init(named: "next.png"))
                confirmBtn.frame = CGRect(x:406, y: ScreenHeight-10, width: 111, height: 48)
                confirmBtn.tag = tag
                confirmBtn.isUserInteractionEnabled = true
                confirmBtn.addGestureRecognizer(MyClick(target: self, action: #selector(nextBtnClick)))
                self.imgView.addSubview(confirmBtn)
            }
        }else{
            if self.step != 0 && self.step != 1
            {
                self.imgView.viewWithTag(tag)?.removeFromSuperview()
            }
        }
        
        
        tag = 903
        if self.view.viewWithTag(tag) == nil {
            if self.step == 2 {
                let confirmBtn = UIImageView(image:UIImage.init(named: "confirm.png"))
                confirmBtn.tag = tag
                confirmBtn.isUserInteractionEnabled = true
                confirmBtn.addGestureRecognizer(MyClick(target: self, action: #selector(uploadBtnClick)))
                confirmBtn.frame = CGRect(x:404, y: ScreenHeight-10, width: 111, height: 48)
                self.imgView.addSubview(confirmBtn)
            }
        }else{
            if self.step != 2
            {
                self.imgView.viewWithTag(tag)?.removeFromSuperview()
            }
        }
    }
    
    func drawLight(lightIndex:Int){
        
        var y:Int = 50
        //setps
        for (index, item)   in steps.enumerated() {
            
            var seq:UILabel = UILabel()
            if self.view.viewWithTag(10+index) == nil{
                seq.tag = 10+index
                seq.frame = CGRect(x:Int(ScreenWidth-80),y:y,width:20,height: 20)
                seq.text = String(index+1)
                seq.textColor = UIColor.white
                seq.font = UIFont.systemFont(ofSize:13)
                seq.textAlignment = NSTextAlignment.center
                seq.layer.cornerRadius = seq.frame.width / 2;
                seq.layer.borderWidth = 1
                seq.clipsToBounds = true;
                seq.layer.masksToBounds = true;
                self.view.addSubview(seq)
            }else{
                seq = self.view.viewWithTag(10+index) as! UILabel
            }
            seq.layer.borderColor = self.step >= index ? checked.cgColor : unchecked.cgColor
            seq.layer.backgroundColor = self.step >= index ? UIColor(red: 0.2, green: 0.73, blue: 0.77, alpha: 1).cgColor:UIColor(red: 0.42, green: 0.42, blue: 0.42, alpha: 1).cgColor
            self.view.bringSubviewToFront(seq)
            
            var label:UILabel = UILabel()
            if self.view.viewWithTag(20+index) == nil
            {
                label.tag = 20+index
                label.frame = CGRect(x:Int(ScreenWidth-50),y:y,width:40,height: 20)
                label.text = item
                label.font = UIFont.systemFont(ofSize:15)
                self.view.addSubview(label)
            }else{
                label = self.view.viewWithTag(20+index) as! UILabel
            }
            label.textColor = self.step >= index ? checked : unchecked
            self.view.bringSubviewToFront(label)
            
            y = Int(label.frame.maxY)
            var line:UILabel = UILabel()
            if self.view.viewWithTag(30+index) == nil  {
                line.tag = 30+index
                line.frame = CGRect(x:Int(ScreenWidth-70),y:y,width:1,height: 30)
                line.layer.borderWidth = 1
                
                self.view.addSubview(line)
            }else{
                line=self.view.viewWithTag(30+index) as! UILabel
            }
            line.layer.borderColor = self.step >= index ? checked.cgColor : unchecked.cgColor
            self.view.bringSubviewToFront(line)
            y = Int(line.frame.maxY)
        }
        
        var line:UILabel = UILabel()
        if self.view.viewWithTag(1) == nil  {
            line.tag = 1
            line.frame = CGRect(x:Int(ScreenWidth-70),y:y,width:1,height: 15)
            line.layer.borderWidth = 1
            
            self.view.addSubview(line)
        }else{
            line=self.view.viewWithTag(1) as! UILabel
        }
        line.layer.borderColor =  self.step == 2 ? checked.cgColor : unchecked.cgColor
        self.view.bringSubviewToFront(line)
        
        y = Int(line.frame.maxY)
        //lights
        for (index, item)   in lights.enumerated() {
            //横线
            var line:UILabel = UILabel()
            if self.view.viewWithTag(40+index) == nil{
                line.tag = 40+index
                line.frame = CGRect(x:Int(ScreenWidth-70),y:y,width:10,height: 1)
                line.layer.borderWidth = 1
                
                self.view.addSubview(line)
            }else{
                line=self.view.viewWithTag(40+index) as! UILabel
            }
            line.layer.borderColor = self.step == 2 && lightIndex >= index ? checked.cgColor : unchecked.cgColor
            self.view.bringSubviewToFront(line)
            //文字
            var label:UILabel = UILabel()
            if self.view.viewWithTag(50+index) == nil
            {
                label.tag = 50+index
                label.frame = CGRect(x:Int(ScreenWidth-50),y:y-10,width:40,height: 20)
                label.text = item
                label.isUserInteractionEnabled = true
                let myClick = MyClick(target: self, action: #selector(viewClick(sender:)))
                myClick.index = index
                label.addGestureRecognizer(myClick)
                label.font = UIFont.systemFont(ofSize:15)
                self.view.addSubview(label)
            }else{
                label = self.view.viewWithTag(50+index) as! UILabel
            }
            label.textColor =  self.step == 2 && lightIndex >= index ? checked : unchecked
            self.view.bringSubviewToFront(label)
            //竖线
            if index != lights.count-1
            {
                var line:UILabel = UILabel()
                if self.view.viewWithTag(60+index) == nil  {
                    line.tag = 60+index
                    line.frame = CGRect(x:Int(ScreenWidth-70),y:y,width:1,height: 45)
                    line.layer.borderWidth = 1
                    
                    self.view.addSubview(line)
                }else{
                    line=self.view.viewWithTag(60+index) as! UILabel
                }
                line.layer.borderColor = self.step == 2 && lightIndex > index ? checked.cgColor : unchecked.cgColor
                self.view.bringSubviewToFront(line)
                
                y = Int(line.frame.maxY)
            }
        }
        
    }
}
extension CustomerMCCarmeraUI: MCBLEDelegate,MCCameraDelegate {
    
    func requestOpenCamera() {
        let alertController =  UIAlertController(title: "通知", message: "需要有相机权限", preferredStyle: UIAlertController.Style.alert)
        
        let cancleAction = UIAlertAction(title: "关闭", style: UIAlertAction.Style.default) { (UIAlertAction) -> Void in
            print("取消按钮点击事件")
        }
        alertController.addAction(cancleAction)
        self.present(alertController, animated: true, completion: nil)
        print("相机权限被拒")
    }
    
    func didGenerateImage(image: UIImage) {
        
        if self.step == 0{
            self.leftImg = image
        }
        if self.step == 1{
            self.rightImg = image
        }
        if self.step == 2{
            self.imgData.append(image.jpegData(compressionQuality: 0.8)!)
        }
        
        DispatchQueue.main.async {
            if self.step == 0 ||  self.step == 1 {
                self.previewView.isHidden = true
                self.camera.session?.stopRunning()
                
                self.drawPreiview(index: -1)
                self.drawLight(lightIndex: -1)
            }
            
            if self.step == 2 {
                
                if self.current == self.end {
                    self.previewView.isHidden = true
                    self.camera.session?.stopRunning()
                    self.auto = false
                    self.drawPreiview(index: self.current)
                    self.drawLight(lightIndex: self.current)
                }else{
                    
                    self.prepareLight(index: self.current+1)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                        self.camera.capture(forLight: self.current)
                    }
                }
            }
        }
    }
    
    func didAdjustFocus() {
        //        print("自动对焦成功:auto:\(auto),prepared:\(self.prepared)")
        //        if  self.auto && self.prepared {
        //            self.camera.capture(forLight: self.current);
        //            self.prepared = false
        //        }
        if self.auto && self.current == 0{
            self.camera.capture(forLight: self.current)
        }
        
    }
    
    func requestOpenBLE() {
        print("蓝牙未打开")
        let alertController =  UIAlertController(title: "通知", message: "蓝牙未打开", preferredStyle: UIAlertController.Style.alert)
        
        let cancleAction = UIAlertAction(title: "关闭", style: UIAlertAction.Style.default) { (UIAlertAction) -> Void in
            print("取消按钮点击事件")
        }
        
        alertController.addAction(cancleAction)
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    func didConnect() {
        print("蓝牙连接成功")
        self.activity.stopAnimating()
        self.label.removeFromSuperview()
        self.prepareLight(index:0)
    }
    
    func didDisconnect() {
        
        let alertController =  UIAlertController(title: "通知", message: "蓝牙连接失败", preferredStyle: UIAlertController.Style.alert)
        
        let cancleAction = UIAlertAction(title: "关闭", style: UIAlertAction.Style.default) { (UIAlertAction) -> Void in
            print("取消按钮点击事件")
        }
        
        alertController.addAction(cancleAction)
        self.present(alertController, animated: true, completion: nil)
        
        print("蓝牙连接失败")
    }
}
