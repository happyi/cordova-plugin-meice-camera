import  UIKit
import  MCCamera
import  MCCameraUI
import  AVKit

//  先在Info.plist设置Allow  Arbitrary  Loads为YES
protocol  MCUIDelegate:NSObjectProtocol{

        func  uploadSuccess(result:Dictionary<String,Any>)

        func  handelError(errMsg:String)
}
class  MyClick:UITapGestureRecognizer{
        var  index:Int  =  0
}

class  CustomerMCCarmeraUI:  UIViewController  {

        weak  var  delegate:  MCUIDelegate?
        var  ble:MCBLE  =  MCBLE()
        var  previewView:MCCameraPreviewView  =  MCCameraPreviewView()
        let  closeBtn  =  UIImageView(image:UIImage.init(named:  "back.png"))
        let  backLabel  =  UILabel()
        let  titleLabel  =  UILabel()
        let  imgView:UIImageView  =  UIImageView()
        var  camera:MCCamera  =  MCCamera()
        var  params:[String  :  String]?
        let  checked:UIColor  =    UIColor(red:  0.2,  green:  0.73,  blue:  0.77,  alpha:  1)
        let  unchecked:UIColor  =      UIColor(red:  0.42,  green:  0.42,  blue:  0.42,alpha:1)

        var  interfaceOrientations:UIInterfaceOrientationMask  =  .portrait{
                didSet{
                        if  interfaceOrientations  ==  .portrait{
                                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue,
                                                                                    forKey:  "orientation")
                        }
                }
        }
        let  shootBtn  =  UIImageView(image:UIImage.init(named:  "caramera.png"))
        let  activity  =  UIActivityIndicatorView(style:  UIActivityIndicatorView.Style.whiteLarge)
        let  label:UILabel  =  UILabel()
        var  ScreenWidth  =  UIScreen.main.bounds.width
        var  ScreenHeight  =  UIScreen.main.bounds.height
        let  statusBar  =  UIApplication.shared.statusBarFrame.size.height
        var  current  =  0
        var  end  =  4
        var  prepared  =  false
        var  auto  =  false
        //        var  luminance  =  [73,90,100,158,153]
        var  luminance  =  [160,160,160,255,255]
        //直接开始连续拍摄
        var  step  =  2
        let  steps  =  ["拍摄"]
        let  lights  =  ["日光","交叉","平行","UV","伍德"]
        var  imgData  =  [Data]()
        var  leftImg:UIImage?
        var  rightImg:UIImage?
        var  audioPlayer:AVPlayer?=nil
        var  playerItem:AVPlayerItem?
        var  initPlay  =  false
        var  playing  =  false

        override  func  viewDidLoad()  {
                super.viewDidLoad()
                //  1.  设置导航栏不透明
                navigationController?.navigationBar.isTranslucent  =  false
                if  ScreenWidth  >  ScreenHeight{
                        let  temp  =  ScreenHeight
                        self.ScreenHeight  =  self.ScreenWidth
                        self.ScreenWidth  =  temp
                }
                print("ScreenWidth:\(ScreenWidth),ScreenHeight:\(ScreenHeight)")
                self.previewView.frame  =  CGRect(x:  0,  y:  -64,  width:  ScreenWidth,  height:  ScreenHeight)
                self.view.addSubview(previewView)
                //loading
                self.activity.frame  =  CGRect(x:  ScreenWidth/2-50,  y:  ScreenHeight/2-50,  width:  100,  height:  100)
                self.activity.backgroundColor  =  UIColor.gray
                self.activity.layer.masksToBounds  =  true
                self.activity.layer.cornerRadius  =  6.0
                self.activity.layer.borderWidth  =  1.0
                self.act
加载更多
