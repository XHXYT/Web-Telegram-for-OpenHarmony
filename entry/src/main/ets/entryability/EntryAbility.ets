import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';
import { AbilityConstant, Configuration, ConfigurationConstant, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';


export default class EntryAbility extends UIAbility {

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
    // 缓存当前设备的颜色模式
    AppStorage.setOrCreate('currentColorMode', this.context.config.colorMode);
  }



  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
      //  let windowClass: window.Window = windowStage.getMainWindowSync(); // 获取应用主窗口
      // 1. 设置窗口全屏
      //  let isLayoutFullScreen = true;
      //  windowClass.setWindowLayoutFullScreen(isLayoutFullScreen);

      // 2. 缓存窗口对象
      // AppStorage.setOrCreate('windowClass', windowClass);

      // 3. 获取布局避让遮挡的区域
      //  let type = window.AvoidAreaType.TYPE_SYSTEM;
      //  let avoidArea = windowClass.getWindowAvoidArea(type);
      // let statusBar =px2vp( avoidArea.topRect.height); // 获取状态栏的高度
      // AppStorage.setOrCreate('statusBar', statusBar);


      let windowClass: window.Window = windowStage.getMainWindowSync(); // 获取应用主窗口
      // 1. 设置窗口全屏
      let isLayoutFullScreen = true;
      windowClass.setWindowLayoutFullScreen(isLayoutFullScreen).then(() => {
        console.info('Succeeded in setting the window layout to full-screen mode.');
      }).catch((err: BusinessError) => {
        console.error('Failed to set the window layout to full-screen mode. Cause:' + JSON.stringify(err));
      });

      // 2. 获取布局避让遮挡的区域
      let type = window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR; // 以导航条避让为例
      let avoidArea = windowClass.getWindowAvoidArea(type);
      let bottomRectHeight = avoidArea.bottomRect.height; // 获取到导航条区域的高度
      AppStorage.setOrCreate('bottomRectHeight', bottomRectHeight);

      type = window.AvoidAreaType.TYPE_SYSTEM; // 以状态栏避让为例
      avoidArea = windowClass.getWindowAvoidArea(type);
      let topRectHeight = avoidArea.topRect.height; // 获取状态栏区域高度
      AppStorage.setOrCreate('topRectHeight', topRectHeight);

      // 3. 注册监听函数，动态获取避让区域数据
      windowClass.on('avoidAreaChange', (data) => {
        if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
          let topRectHeight = data.area.topRect.height;
          AppStorage.setOrCreate('topRectHeight', topRectHeight);
        }
        //        else if (data.type == window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
        //         let bottomRectHeight = data.area.bottomRect.height;
        //       AppStorage.setOrCreate('bottomRectHeight', bottomRectHeight);
        //   }

      });
    });
  }






  onWindowStageDestroy() {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground() {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground() {
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    AppStorage.setOrCreate('currentColorMode', newConfig.colorMode);
    hilog.info(0x0000, 'testTag', 'the newConfig.colorMode is %{public}s',
      JSON.stringify(AppStorage.get('currentColorMode')) ?? '');

    // 监听系统配置变更
    let newColorMode = newConfig.colorMode;
    let currentColorMode = AppStorage.get<ConfigurationConstant.ColorMode>('currentColorMode');
    if (newColorMode === currentColorMode) {
      return;
    }
    // 更新缓存中的颜色模式
    AppStorage.setOrCreate('currentColorMode', newConfig.colorMode);
  }

}






