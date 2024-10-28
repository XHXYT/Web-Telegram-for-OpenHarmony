import { webview } from '@kit.ArkWeb';
import hilog from '@ohos.hilog';
import deviceInfo from '@ohos.deviceInfo'
import { BusinessError } from '@kit.BasicServicesKit';
import { fileUri, fileIo as fs, picker } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { connection } from '@kit.NetworkKit';
import { wantAgent, WantAgent } from '@kit.AbilityKit';
import { notificationManager } from '@kit.NotificationKit';


// no User Agent, test
// https://tool.lu/useragent
// Mozilla/5.0 (X11; Linux aarch64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.88 Mobile Safari/537.36

// User Agent set in the offcial browser
// const PAD_USER_AGENT: string = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTMl, like Gecko) Chrome/92.0.4515.105 Safari/537.36'
// const PHONE_USER_AGENT: string = 'Mozilla/5.0 (Linux; Android 9; VRD-AL10; HMSCore 6.3.0.331) AppleWebKit/537.36 (KHTMl, like Gecko) Chrome/92.0.4515.105 HuaweiBrowser/12.0.4.1 Mobile Safari/537.36'

// User Agent modification from westinyang
const PAD_USER_AGENT: string =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTMl, like Gecko) Chrome/99.0.4844.88 Safari/537.36'
const PHONE_USER_AGENT: string =
  'Mozilla/5.0 (Linux; Android 10.0; ohos) AppleWebKit/537.36 (KHTMl, like Gecko) Chrome/99.0.4844.88 HuaweiBrowser/13.0.4.302 Mobile Safari/537.36'

const TAG: string = '[PublishOperation]';
const DOMAIN_NUMBER: number = 0xFF00;

//请求通知授权
let context = getContext(this) as common.UIAbilityContext;
notificationManager.isNotificationEnabled().then((data: boolean) => {
  hilog.info(DOMAIN_NUMBER, TAG, "isNotificationEnabled success, data: " + JSON.stringify(data));
  if (!data) {
    notificationManager.requestEnableNotification(context).then(() => {
      hilog.info(DOMAIN_NUMBER, TAG, `[ANS] requestEnableNotification success`);
    }).catch((err: BusinessError) => {
      if (1600004 == err.code) {
        hilog.error(DOMAIN_NUMBER, TAG,
          `[ANS] requestEnableNotification refused, code is ${err.code}, message is ${err.message}`);
      } else {
        hilog.error(DOMAIN_NUMBER, TAG,
          `[ANS] requestEnableNotification failed, code is ${err.code}, message is ${err.message}`);
      }
    });
  }
}).catch((err: BusinessError) => {
  hilog.error(DOMAIN_NUMBER, TAG, `isNotificationEnabled fail, code is ${err.code}, message is ${err.message}`);
});

// Define the interface for the extended object
interface ExtObject {
  test: (str: string) => string;
}

connection.addCustomDnsRule("https://web.telegram.org/k/",
  ["149.154.167.99", "128.121.243.106", "108.160.162.109", "149.154.167.99",
    "31.13.67.41", "50.23.209.199", "50.23.209.199 ", "103.240.180.117",
  ],
  (error: BusinessError, data: void) => {
    if (error) {
      console.error(`Failed to get add custom dns rule. Code:${error.code}, message:${error.message}`);
      return;
    }
    console.info("Succeeded to get data: " + JSON.stringify(data));
  })

@Entry
@Component
struct Index {
  @State isPhone: boolean = false
  @State access: boolean = true
  @State isClick: boolean = false;
  @State isShow: boolean = false;
  @State realUri: string = "";
  @State showing_downloads: boolean = true;
  @State DownloadPercentComplete: number = 0;
  @State DownloadProgressValue: string = "";
  @State DownloadFileName: string = "";
  @State DownloadList: string = "";
  @State DownloadSpeed: string = "";
  @State DownloadTotalBytes: string = "";
  @State DownloadState: string = "";
  @State DownloadReceivedBytes: number = 0;
  @State DownloadTimeRemaining: string = '';
  @State mode: WebDarkMode = WebDarkMode.Auto;
  @State scrollmode: OverScrollMode = OverScrollMode.ALWAYS;
  @State handler: FullScreenExitHandler | null = null; //通知开发者Web组件进入或退出全屏模式
  @State sandboxFilePath: string = "/data/storage/el1/bundle/cache" //文件的沙箱路径
  @State statusBar: number = AppStorage.get<number>('statusBar') as number;
  @StorageProp('bottomRectHeight') bottomRectHeight: number = 0;
  @StorageProp('topRectHeight') topRectHeight: number = 0;
  controller: webview.WebviewController = new webview.WebviewController()
  delegate: webview.WebDownloadDelegate = new webview.WebDownloadDelegate()

  // Implement the extended browser object
  extObj: ExtObject = {
    test: (str: string): string => {
      console.log("extObj.test: " + str);
      return "test " + str;
    }
  };

  aboutToAppear(): void {
    try {
      let deviceType: string = deviceInfo.deviceType;
      console.log(`device type:${deviceType}`)
      //  default is considered as phone
      if (deviceType === 'phone' || deviceType === 'default') {
        this.isPhone = true
      } else if (deviceType === 'phone' || deviceType === 'default') {

      }
    } catch (e) {
      hilog.info(0x0, '[Index]', `getSync unexpected error: ${e}`)
    }
  }

  build() {
    Column() {
      Stack() {
        Web({
          src: 'https://web.telegram.org/k/',
          controller: this.controller
        })//$rawfile('index.html')   'https://web.telegram.org/k/'   'http://miss.qingchengkg.cn/'
          .darkMode(this.mode)
          .forceDarkAccess(this.access)
          .zoomAccess(false)
          .mediaPlayGestureAccess(true)
          .horizontalScrollBarAccess(false)
          .verticalScrollBarAccess(false)
          .fileAccess(true)
          .imageAccess(true)
          .onlineImageAccess(true)
          .domStorageAccess(true)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
          .databaseAccess(true)
          .javaScriptAccess(true)//通知开发者Web组件进入全屏模式
          .onFullScreenEnter((event) => {
            console.log("onFullScreenEnter videoWidth: " + event.videoWidth +
              ", videoHeight: " + event.videoHeight);
            // 应用可以通过 this.handler.exitFullScreen() 主动退出全屏。
            this.handler = event.handler;
          })//通知开发者Web组件退出全屏模式
          .onFullScreenExit(() => {
            console.log("onFullScreenExit...")
            if (this.handler) {
              this.handler.exitFullScreen();
            }
          })//上传文件(支持媒体与资源文件)
          .onShowFileSelector((event) => {
            console.log('MyFileUploader onShowFileSelector invoked');
            const documentSelectOptions = new picker.DocumentSelectOptions();
            // 选择文档的最大数目（可选）
            documentSelectOptions.maxSelectNumber = 5;
            // 指定选择的文件或者目录路径（可选）
            //documentSelectOptions.defaultFilePathUri = "file://docs/storage/Users";
            // 选择文件的后缀类型['后缀类型描述|后缀类型']（可选） 若选择项存在多个后缀名，则每一个后缀名之间用英文逗号进行分隔（可选），后缀类型名不能超过100,选择所有文件：'所有文件(*.*)|.*';
            documentSelectOptions.fileSuffixFilters =
              ['图片(.png, .jpg)|.png,.jpg', '文档|.txt', '视频|.mp4', '.pdf', '.zip', '音频|.mp3,.flac',
                '软件|.apk,.hap,.app,.ipa', '所有文件(*.*)|.*'];
            //选择是否对指定文件或目录授权，true为授权，当为true时，defaultFilePathUri为必选参数，拉起文管授权界面；false为非授权，拉起常规文管界面（可选）
            documentSelectOptions.authMode = true;

            this.selectFile().then((selected) => {
              if (selected) {
                let fileList: Array<string> = [this.sandboxFilePath,]
                event.result.handleFileList(fileList)
              }
            })
            return true
          })//文件下载通知
          .onDownloadStart((event) => {
            if (event) {
              console.log('url:' + event.url)

            }
          })
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
          .javaScriptProxy({
            object: this.extObj,
            name: "extObj",
            methodList: ["test"],
            controller: this.controller,
          })
          .onControllerAttached(() => {
            console.log("onControllerAttached");
            try {
              let userAgent = this.isPhone ? PHONE_USER_AGENT : PAD_USER_AGENT;
              this.controller.setCustomUserAgent(userAgent);
            } catch (error) {
              console.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
            }
          })
          .onPageBegin((event) => {
            hilog.info(0x0, '[Index]', `onPageBegin= ${JSON.stringify(event)}`)
          })
          .onPageEnd((event) => {
            hilog.info(0x0, '[Index]', `onPageEnd= ${JSON.stringify(event)}`)
            try {
              //创建文件选择器实例
              let downloaduri: string = '';
              // 请确保 getContext(this) 返回结果为 UIAbilityContext
              let context = getContext(this) as common.Context;
              const documentViewPicker = new picker.DocumentViewPicker(context);
              const documentSaveOption = new picker.DocumentSaveOptions();
              documentSaveOption.pickerMode = picker.DocumentPickerMode.DOWNLOAD;
              documentViewPicker.save(documentSaveOption)
                .then((documentSaveResult: Array<string>) => {
                  downloaduri = documentSaveResult[0];
                  console.info('documentViewPicker.save succeed and downloaduri is:' + downloaduri);
                }).catch((err: BusinessError) => {
                console.error(`Invoke documentViewPicker.save failed, code is ${err.code}, message is ${err.message}`);
              })

              this.delegate.onBeforeDownload((webDownloadItem: webview.WebDownloadItem) => {
                console.log("will start a download.");
                // 将得到的downloaduri，使用FileUri做一层转换之后，才可以做后续读写的操作！！！
                // 将得到的downloaduri，使用FileUri做一层转换之后，才可以做后续读写的操作！！！
                // 将得到的downloaduri，使用FileUri做一层转换之后，才可以做后续读写的操作！！！
                let path: string = new fileUri.FileUri(downloaduri).path
                // 传入一个下载路径，如果传入一个不存在的路径，则会下载到默认/data/storage/el2/base/cache/web/目录
                let filePath = path + "/" + webDownloadItem.getSuggestedFileName()
                //这边要多加一个fs.OpenMode.CREATE得到创建文件的权限(实测好像不需要申请也行，并且应该是我不会写的缘故，一开下面这个运行下载直接重启（ )
                //let file  = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
                // 开始下载
                webDownloadItem.start(filePath);
                promptAction.showToast({ message: "开始下载" })
                //获取下载件名称
                this.DownloadFileName = webDownloadItem.getSuggestedFileName()

              })
              this.delegate.onDownloadUpdated((webDownloadItem: webview.WebDownloadItem) => {
                // 下载任务的唯一标识。
                console.log("download update guid: " + webDownloadItem.getGuid());

                // 下载文件的总长度
                this.DownloadTotalBytes = (webDownloadItem.getTotalBytes() / 1024 / 1024).toFixed(2) + 'MB'
                console.log("下载文件的总长度 : " + this.DownloadTotalBytes)

                // 下载的进度。
                console.log("download update guid: " + webDownloadItem.getPercentComplete())
                this.DownloadPercentComplete = webDownloadItem.getPercentComplete()
                this.DownloadProgressValue = this.DownloadPercentComplete + '%'
                console.log("下载进度 : " + this.DownloadProgressValue)

                // 当前的下载速度。
                console.log("download update speed: " + webDownloadItem.getCurrentSpeed())
                this.DownloadSpeed = (webDownloadItem.getCurrentSpeed() / 1024 / 1024).toFixed(2) + 'MB/s'
                console.log("下载速度 : " + this.DownloadSpeed)

                //已接收字节数
                this.DownloadReceivedBytes = webDownloadItem.getReceivedBytes()
                //剩余时间
                this.DownloadTimeRemaining =' | ' + ((webDownloadItem.getTotalBytes() - this.DownloadReceivedBytes) / webDownloadItem.getCurrentSpeed()).toFixed(0) + 's'
                if (this.DownloadTimeRemaining == ' | NaNs') {
                  this.DownloadTimeRemaining = ''
                }

                // 下载的状态
                if (this.DownloadPercentComplete == 100) {
                  this.DownloadState = '下载完成'
                } else {
                  this.DownloadState = '正在下载'
                }
                console.log("下载状态 : " + this.DownloadState)

                // 用于保存创建成功的wantAgent对象，后续使用其完成触发的动作。
                let wantAgentObj:WantAgent;
                // 通过WantAgentInfo的operationType设置动作类型
                let wantAgentInfo:wantAgent.WantAgentInfo = {
                  wants: [
                    {
                      deviceId: '',
                      bundleName: 'org.ohos.webtelegram',
                      abilityName: 'EntryAbility',
                      action: '',
                      entities: [],
                      uri: '',
                      parameters: {}
                    }
                  ],
                  actionType: wantAgent.OperationType.START_ABILITY,
                  requestCode: 0,
                  wantAgentFlags:[wantAgent.WantAgentFlags.CONSTANT_FLAG]
                };
                // 创建WantAgent
                wantAgent.getWantAgent(wantAgentInfo, (err: BusinessError, data:WantAgent) => {
                  if (err) {
                    hilog.error(DOMAIN_NUMBER, TAG, `Failed to get want agent. Code is ${err.code}, message is ${err.message}`);
                    return;
                  }
                  hilog.info(DOMAIN_NUMBER, TAG, 'Succeeded in getting want agent.');
                  wantAgentObj = data;
                });

                //查询系统是否支持进度条模板
                notificationManager.isSupportTemplate('downloadTemplate').then((data: boolean) => {
                  hilog.info(DOMAIN_NUMBER, TAG, 'Succeeded in supporting download template notification.');
                  let isSupportTpl: boolean = data; // isSupportTpl的值为true表示支持downloadTemplate模板类通知，false表示不支持
                  //构造进度条模板对象
                  if (data = true) {
                    //去除后缀名
                    let fullFileName: string = this.DownloadFileName
                    let thefileName: string = this.getFileName(fullFileName) + '  ' + this.DownloadState
                    console.log('文件名为：' + thefileName)
                    this.DownloadList = this.DownloadProgressValue + ' | ' + this.DownloadTotalBytes + ' | ' + this.DownloadSpeed + this.DownloadTimeRemaining

                    let notificationRequest: notificationManager.NotificationRequest = {
                      id: 5,
                      // wantAgentObj使用前需要保证已被赋值
                      wantAgent: wantAgentObj,
                      content: {
                        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
                        normal: {
                          title: 'test_title',
                          text: 'test_text',
                          additionalText: 'test_additionalText'
                        }
                      },
                      // 构造进度条模板，name字段当前需要固定配置为downloadTemplate
                      template: {
                        name: 'downloadTemplate',
                        data: {
                          title: thefileName,
                          fileName: this.DownloadList,
                          progressValue: this.DownloadPercentComplete
                        }
                      }
                    }
                    // 发布通知
                    notificationManager.publish(notificationRequest, (err: BusinessError) => {
                      if (err) {
                        hilog.error(DOMAIN_NUMBER, TAG,
                          `Failed to publish notification. Code is ${err.code}, message is ${err.message}`);
                        return;
                      }
                      hilog.info(DOMAIN_NUMBER, TAG, 'Succeeded in publishing notification.');
                    });
                  } else {
                    console.error('当前设备不支持进度条模板')
                  }
                }).catch((err: BusinessError) => {
                  hilog.error(DOMAIN_NUMBER, TAG, `不支持下载进度通知. Code is ${err.code}, message is ${err.message}`);
                });

              })
              this.delegate.onDownloadFailed((webDownloadItem: webview.WebDownloadItem) => {
                console.log("download failed guid: " + webDownloadItem.getGuid());
                // 下载任务失败的错误码。
                console.log("download failed guid: " + webDownloadItem.getLastErrorCode());
              })
              this.delegate.onDownloadFinish((webDownloadItem: webview.WebDownloadItem) => {
                console.log("download finish guid: " + webDownloadItem.getGuid());
                promptAction.showToast({ message: "下载完成" })
                //console.log("下载完成");
              })
              this.controller.setDownloadDelegate(this.delegate);
            } catch (error) {
              console.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
            }

          })
          .onProgressChange((event) => {
            hilog.info(0x0, '[Index]', `onProgressChange`)
          })

        Button({ type: ButtonType.Circle, stateEffect: false }) {
          Image(this.isClick ? $r('app.media.xmark') : $r('app.media.arrow_up_to_line'))
            .interpolation(ImageInterpolation.High)
            .fillColor(Color.White)
            .rotate({
              x: 0,
              y: 0,
              z: 1,
              centerX: '50%',
              centerY: '50%',
              angle: 180
            })
            .width(25)
            .height(25)
        }
        .backgroundColor(0x3390ec)
        .shadow({ radius: 5 })
        .position({ x: '4.6%', y: '92.4%' })
        .width(54)
        .height(54)
        .onClick(() => {
          this.changeClick(!this.isClick)
          this.isShow = !this.isShow
        })

        if (this.isShow) {
          Column() {
            Column() {
              Text($r('app.string.Index_downloads_title'))
                .textAlign(TextAlign.Start)
              Text('这里什么都还没有哦 ( ´ ▽ ` )ﾉ')
                .textAlign(TextAlign.Center)



            }
            //阻止卡片内点击隐藏
            .onClick(() => {
              this.isShow = true
            })
            .padding(5)
            .position({ x: '7%', y: '17%' })
            .borderRadius(10)
            .backgroundColor($r('app.color.start_window_background'))
            .shadow({ radius: 16 })
            .width('85%')
            .height('80%')

            //.backgroundColor(Color.Blue)
          }
          .width('100%')
          .height('88%')
          //.backgroundColor(Color.Pink)
          .onClick(() => {
            this.isShow = !this.isShow
          })

        }


      }
      .backgroundColor($r('app.color.background_color'))
      .width('100%')
      .height('100%')
      .padding({ top: px2vp(this.topRectHeight), }) //bottom: px2vp(this.bottomRectHeight) })
      //.padding({ top: this.statusBar }) // 此处margin或padding具体数值在实际中应与状态栏区域高度保持一致
      .onAreaChange((_o, n) => {
      })

    }

  }

  onBackPress() {
    // 当前页面是否可前进或者后退给定的step步(-1),正数代表前进，负数代表后退
    if (this.controller.accessStep(-1)) {
      this.controller.backward(); // 返回上一个web页
      // 执行用户自定义返回逻辑

      return true;
    } else {
      // 执行系统默认返回逻辑，返回上一个page页
      return false;
    }
  }

  //选择上传的文件
  async selectFile(): Promise<boolean> {
    //选择任意文件
    let filePicker = new picker.DocumentViewPicker();
    let result = await filePicker.select();
    if (result.length > 0) {
      return this.copySelFile2Sandbox(result[0])
    }
    return false
  }

  //复制资源文件到沙箱
  async copyResFile2Sandbox(resFile: string): Promise<boolean> {
    let context = getContext(this)
    //计划复制到的目标路径
    this.realUri = context.cacheDir + "/" + resFile
    let rawFd = await context.resourceManager.getRawFd(resFile)

    //复制资源文件到沙箱cache文件夹
    try {
      fs.copyFileSync(rawFd.fd, this.realUri)
      this.sandboxFilePath = this.realUri
      return true
    } catch (err) {
      console.error(err.message)
    }
    return false
  }

  //复制选中文件到沙箱
  copySelFile2Sandbox(selectFile: string): boolean {
    let context = getContext(this)
    let segments = selectFile.split('/')
    //文件名称
    let fileName = segments[segments.length-1]
    //计划复制到的目标路径
    this.realUri = context.cacheDir + "/" + fileName
    //复制选择的文件到沙箱cache文件夹
    try {
      let file = fs.openSync(selectFile);
      fs.copyFileSync(file.fd, this.realUri)
      this.sandboxFilePath = this.realUri
      return true
    } catch (err) {
      console.error(err.message)
    }
    return false
  }

  private changeClick(isClick: boolean) {
    animateTo({ duration: 200, curve: Curve.EaseInOut }, () => {
      this.isClick = !this.isClick;
      this.showing_downloads = !this.showing_downloads;
    })
  }

  // 使用 substring 和 lastIndexOf 方法来获取不带后缀的文件名
  private getFileName(fullFileName: string) {
    // 查找最后一个点的位置
    let lastDotIndex: number = fullFileName.lastIndexOf(".");
    // 如果没有找到点或者点在字符串的开始或结束位置，则返回整个字符串
    if (lastDotIndex < 1) {
      return fullFileName;
    }
    // 截取文件名（不包括后缀）
    return fullFileName.substring(0, lastDotIndex);
  }

  aboutToDisappear() {
    console.info('MyComponent aboutToDisappear')
    //退出应用时删除cache目录
    fs.rmdir(this.realUri).then(() => {
      console.info("rmdir succeed");
    }).catch((err: BusinessError) => {
      console.error("rmdir failed with error message: " + err.message + ", error code: " + err.code);
    });
  }

}










