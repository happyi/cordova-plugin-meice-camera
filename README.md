cordova-plugin-meice-camera
===================

## 安装插件

	cordova plugin add https://github.com/happyi/cordova-plugin-meice-camera.git

  或者

  cordova plugin add cordova-plugin-meice-camera


## 使用方法

	使用案例  https://github.com/happyi/mc-demo.git

```javascript

      var isProd = false

 			var  deviceNumber = "MC680-C4C7DF290EF4";
            var customer ={
                    "name": "Al",
                    "phone": "18511111111",
                    "sex": "0",
                    "year": "1991",
                    "month": "11",
                    "day": "08",
                    "age": "27",
                    "extra": "deviceId=MC680-C4C7DF290EF4&custId=402881f167721fe70167ba816f105020",
                    "unionid": "402881f167721fe70167ba816f105020"
            };
            window.MCCamera.shoot(isProd,deviceNumber,customer,
                                  function(data){
                                  console.log("js success->customerPicId:"+data.customerPicId+",leftImg:"+data.leftImg+",rightImg:"+data.rightImg)
                            
                                  },
                                  function(errMsg){
                                   console.log("js error: "+errMsg)
                                  }
                                  
             );
        
    
```
返回结果
```
 {
   "customerPicId":"",
   "leftImgPath":"",
   "leftImg":"",
   "rightImgPath":"",
   "rightImg":""
 }

```

npm publish --registry=https://registry.npmjs.org/

