
import Foundation
import UIKit
import MCCamera
import MCCameraUI

class DetectionResult {
    var customerPicId:String = ""
    var leftImgUrl:String = ""
    var rightImgUrl:String = ""
    var tags:[String] = [String]()
}

// 先在Info.plist设置Allow Arbitrary Loads为YES
@objc(MCCameraSwiftPlugin) class  MCCameraSwiftPlugin : CDVPlugin{
    
    var pluginResult:CDVPluginResult?
    var command:CDVInvokedUrlCommand?
    var debug = true
    
    func pluginInit(isProd:Bool) {
        if isProd{
             MCApi.server = "http://open.meiquc.cn/api/rest/"
             MCApi.uploadserver = "http://algorithm.meiquc.cn/api/compute"
        }else{
            MCApi.server = "http://open-test.meiquc.cn/api/rest/"
            MCApi.uploadserver = "http://alg-test.meiquc.cn/api/compute"
        }
    }
    
    @objc(shoot:) func shoot(command:CDVInvokedUrlCommand) {
        self.command = command
        if command.arguments == nil || command.arguments.count < 3{
            self.pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR,messageAs:"参数不正确")
            self.commandDelegate.send(self.pluginResult, callbackId: command.callbackId)
            return
        }
        let isProd = command.arguments[0] as! Bool
        
        let deviceNumber = command.arguments[1] as? String
        
        if deviceNumber == nil {
            self.pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR,messageAs:"设备号不能为空")
            self.commandDelegate.send(self.pluginResult, callbackId: command.callbackId)
            return
        }

        let params = command.arguments[2] as! [String : String]
        
        print("deviceNumber:\(String(describing: deviceNumber))")
        print("params:\(params)")

        self.pluginInit(isProd: isProd)
        // 1.  初始化Api，传设备码和密钥（到时会分配给你一个），只有成功后才能进行后续操作，否则后续操作结果未知
        MCApi.setup(deviceNumber:deviceNumber!, secret:"d12139cc8ab1b1e384914674d4b680d8b060ab583b7281fd421a983401fab60f", sucessBlock: {
            
            // 2. 进入拍照界面
            // 1. 这个参数就是根据不同客户进行不同定义, 下面列出的key必须有，unionid就是你们系统中的客户id
            //            let params = ["name": "Al", "phone": "18511111111", "sex": "0", "year": "1991", "month": "11", "day": "08", "age": "27", "extra": "deviceId=MC680-C4C7DF290EF4&custId=xxx", "unionid": "xxx"]
            
            // 2. 在拍照前必须调用些方法，成功后才能进入拍照界面，否则后续操作结果未知
            MCApi.setupBeforeShoot(userParams: params, sucessBlock: {
                // 3. 初始化拍照界面并设置代理
                DispatchQueue.global(qos: .userInitiated).async {
                    
                    DispatchQueue.main.async {
                        let ui = CustomerMCCarmeraUI()
                        ui.delegate = self
                        ui.params = params
                        
//                        let ui = MCShootVC()
//                        ui.delegate = self
                
                        self.viewController.present(ui, animated: true, completion: nil)
                    }
                }
                
            }, failureBlock: { (errCode, errMsg) in
                
                self.pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR,messageAs:"Failed to setup before shoot: error code: \(errCode), error message: \(errMsg)")
                self.commandDelegate.run {
                    self.commandDelegate.send(self.pluginResult, callbackId: command.callbackId)
                }
            })
        }) { (errCode, errMsg) in
            
            self.pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR,messageAs:"Failed to setup MCApi: error code: \(errCode), error message: \(errMsg)")
            self.commandDelegate.run {
                self.commandDelegate.send(self.pluginResult, callbackId: command.callbackId)
            }
        }
    }
}

// 拍照界面代理和分析结果界面代理
extension MCCameraSwiftPlugin: MCUIDelegate,MCShootVCDelegate {
    
    func uploadSuccess(shootId: String) {
        
    }
    
    func uploadFailed(errCode: String, errMsg: String) {
        
    }
    
    
    func uploadSuccess(result:Dictionary<String,Any>)
    {
        self.pluginResult = CDVPluginResult(status: CDVCommandStatus_OK,messageAs:result)
        self.commandDelegate.run {
            self.commandDelegate.send(self.pluginResult, callbackId: self.command?.callbackId)
        }
        self.viewController.dismiss(animated: true, completion: nil)
    }
    
    func handelError(errMsg:String){
        self.pluginResult = CDVPluginResult(status:CDVCommandStatus_ERROR,messageAs:"\(errMsg)")
       
        self.commandDelegate.run {
            self.commandDelegate.send(self.pluginResult, callbackId: self.command?.callbackId)
        }
         self.viewController.dismiss(animated: true, completion: nil)
    }
}
