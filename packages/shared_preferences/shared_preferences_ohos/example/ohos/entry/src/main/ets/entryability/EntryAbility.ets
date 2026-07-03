import { FlutterAbility } from '@ohos/flutter_ohos'
import { GeneratedPluginRegistrant } from '../plugins/GeneratedPluginRegistrant';
import FlutterEngine from '@ohos/flutter_ohos/src/main/ets/embedding/engine/FlutterEngine';
import data_preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { bundleManager } from '@kit.AbilityKit';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import hilog from '@ohos.hilog';

const TAG = 'SharedPreferencesExample';
const DEFAULT_SHARED_PREFERENCES_SUFFIX = '_preferences';
const PRESET_STRING_KEY = 'thisStringIsWrittenInTheExampleAppJavaCode';
const PRESET_INT_KEY = 'thisIntIsWrittenInTheExampleAppJavaCode';

export default class EntryAbility extends FlutterAbility {
  configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    this.seedDefaultSharedPreferences();
    GeneratedPluginRegistrant.registerWith(flutterEngine);
  }

  private seedDefaultSharedPreferences(): void {
    try {
      const context = this.context.getApplicationContext() as common.ApplicationContext;
      const flag: bundleManager.BundleFlag =
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION;
      const bundleInfo: bundleManager.BundleInfo =
        bundleManager.getBundleInfoForSelfSync(flag);
      const bundleName = bundleInfo.name;
      const defaultPreferencesName = `${bundleName}${DEFAULT_SHARED_PREFERENCES_SUFFIX}`;

      this.writePresetValues(context, defaultPreferencesName);
    } catch (err) {
      hilog.error(0x0000,TAG, 'Failed to seed default shared preferences: %{public}s', JSON.stringify(err) ?? '');
    }
  }

  private writePresetValues(
    context: common.ApplicationContext,
    preferencesName: string,
  ): void {
    const preferences = data_preferences.getPreferencesSync(context, {
      name: preferencesName,
    });
    preferences.putSync(PRESET_STRING_KEY, 'testString');
    preferences.putSync(PRESET_INT_KEY, 5);
    preferences.flushSync();
  }
}
