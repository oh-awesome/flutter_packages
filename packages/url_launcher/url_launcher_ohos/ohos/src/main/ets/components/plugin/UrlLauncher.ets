/*
 * Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';
import BasicMessageChannel, { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';
import Want from '@ohos.app.ability.Want';
import wantConstant from '@ohos.app.ability.wantConstant';
import fileuri from '@ohos.file.fileuri';
import { FlutterError, UrlLauncherApi, UrlLauncherApiCodec, WebViewOptions, BrowserOptions, wrapError } from './Messages';
import common from '@ohos.app.ability.common';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import call from '@ohos.telephony.call';
import i18n from '@ohos.i18n';
import bundleManager from '@ohos.bundle.bundleManager';
import router from '@ohos.router'
import promptAction from '@ohos.promptAction';
import { BusinessError } from '@kit.BasicServicesKit';
import { emitter } from '@kit.BasicServicesKit';

const TAG = 'UrlLauncher'

class SendMessageParams {
  telephone: string = '';
  telephoneFormat: string = '';
  contactName: string = '';
}

export class UrlLauncher implements UrlLauncherApi {
  static LAUNCH_TYPE_TEL: string = 'tel:';
  static LAUNCH_TYPE_WEB_HTTP: string = 'http:';
  static LAUNCH_TYPE_WEB_HTTPS: string = 'https:';
  static LAUNCH_TYPE_MAILTO: string = 'mailto:';
  static LAUNCH_TYPE_SMS: string = 'sms:';
  static LAUNCH_TYPE_FILE: string = 'file:';
  static LAUNCH_TYPE_APP_GALLERY: string = 'store:';
  static LAUNCH_TYPE_ENTERPRISE: string = 'store://enterprise' // 添加企业安装方式

  static MMS_BUNDLE_NAME = 'com.ohos.mms';
  static MMS_ABILITY_NAME = 'com.ohos.mms.MainAbility';
  static MMS_ENTITIES = 'entity.system.home';
  static SMS_QUERY_BODY_REGEX: RegExp = /(?:^|&)body=([^&]*)/;

  private context: common.UIAbilityContext;

  constructor(ctx: common.UIAbilityContext) {
    this.context = ctx;
  }

  canLaunchUrl(url: string): boolean {
    if (!url || url.trim().length === 0) {
      Log.e(TAG, 'canLaunchUrl: url is empty');
      return false;
    }
    let encodedUri = encodeURI(url);
    // 先尝试用 canOpenLink 动态验证处理应用是否存在（与 Android resolveActivity 行为对齐）
    try {
      if (bundleManager.canOpenLink(encodedUri)) {
        return true;
      }
    } catch (error) {
      // Trick：由于 sms、tel、file、mailto 用 bundleManager.canOpenLink 判断会报 17700055 错误，
      // 这些内置协议回退到前缀判断（无法完全验证处理应用存在性，见 README 平台限制说明）
      Log.e(TAG, 'canOpenLink error: ', JSON.stringify(error));
    }
    if (encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_TEL) ||
        encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_WEB_HTTP) ||
        encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_WEB_HTTPS) ||
        encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_MAILTO) ||
        encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_SMS) ||
        encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_FILE) ||
        encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_APP_GALLERY)) {
      return true;
    }
    return false;
  }

  async launchUrl(url: string, headers: Map<string, string>): Promise<boolean> {
    if (!url || url.trim().length === 0) {
      // 抛出具体错误码，便于 Flutter 层区分失败原因（原仅 return false）
      throw new FlutterError('INVALID_URL', 'URL must not be empty', null);
    }
    if (!headers) {
      headers = new Map<string, string>();
    }
    if (!this.canLaunchUrl(url)) {
      // 抛出具体错误码，便于 Flutter 层区分"无应用可处理"场景
      throw new FlutterError('CANNOT_LAUNCH', 'No application can handle the URL: ' + url, null);
    }

    this.ensureContext();
    let encodedUri = encodeURI(url);
    Log.d(TAG, 'launchUrl. url:' + url + '  eurl:' + encodedUri);
    if (encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_TEL)) {
      return await this.launchTel(url);
    } else if (encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_WEB_HTTP) ||
               encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_WEB_HTTPS)) {
      return await this.launchWeb(url, headers);
    } else if (encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_MAILTO)) {
      return await this.launchMail(url);
    } else if (encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_SMS)) {
      return await this.launchSms(url);
    } else if (encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_FILE)) {
      return await this.launchFile(url);
    } else if (encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_ENTERPRISE)) {
      return await this.launchOther(url);
    } else if (encodedUri.startsWith(UrlLauncher.LAUNCH_TYPE_APP_GALLERY)) {
      return await this.launchAppGallery(url);
    } else {
      return await this.launchOther(url);
    }
  }

  format(number: string): string {
    // 参数校验：避免 null/undefined/空字符串触发 number.replace TypeError
    if (!number || typeof number !== 'string' || number.trim().length === 0) {
      Log.e(TAG, 'format: number is empty or invalid');
      return '';
    }
    let regex: RegExp = /\s/g;
    let phoneNumber = number.replace(regex, '');
    let countryId = i18n.getSystemRegion();
    let phoneNumberFormat= new i18n.PhoneNumberFormat(countryId);
    let isNumberValid:boolean = phoneNumberFormat.isValidNumber(phoneNumber);
    let formatNumber = isNumberValid ? phoneNumberFormat.format(phoneNumber) : phoneNumber;
    return formatNumber;
  }

  async launchSms(url: string): Promise<boolean> {
    let smsUrl = this.parseUrl(url, UrlLauncher.LAUNCH_TYPE_SMS);
    if (!smsUrl || smsUrl.trim().length === 0) {
      Log.e(TAG, 'launchSms: sms url is empty, url: %s', url);
      throw new FlutterError('INVALID_URL', 'SMS url is empty', null);
    }
    let phoneNumber: string = '';
    let messageBody: string = '';

    let questionMarkIndex = smsUrl.indexOf('?');
    if (questionMarkIndex !== -1) {
      let queryString = smsUrl.substring(questionMarkIndex + 1);
      phoneNumber = smsUrl.substring(0, questionMarkIndex);
      let bodyMatch = queryString.match(UrlLauncher.SMS_QUERY_BODY_REGEX);
      if (bodyMatch) {
        try {
          messageBody = decodeURIComponent(bodyMatch[1]);
        } catch (e) {
          Log.e(TAG, 'decodeURIComponent failed for sms body, raw: ' + bodyMatch[1]);
          messageBody = bodyMatch[1];
        }
      }
    } else {
      phoneNumber = smsUrl;
    }
    try {
      phoneNumber = decodeURIComponent(phoneNumber).replace(/\s+/g, '');
    } catch (e) {
      Log.e(TAG, 'decodeURIComponent failed for phone number, raw: ' + phoneNumber);
      phoneNumber = phoneNumber.replace(/\s+/g, '');
    }
    let formatNum = this.format(phoneNumber);

    let msgParam = new SendMessageParams();
    msgParam.telephone = phoneNumber;
    msgParam.telephoneFormat = formatNum;

    let params: SendMessageParams[] = [];
    params.push(msgParam);

    let actionData: Record<string, Object> = {};
    actionData.contactObjects = JSON.stringify(params);
    actionData.pageFlag = 'conversation';
    if (messageBody) {
      actionData.content = messageBody;
    }
    let str: Want = {
      'bundleName': UrlLauncher.MMS_BUNDLE_NAME,
      'abilityName': UrlLauncher.MMS_ABILITY_NAME,
      'parameters': actionData,
      'entities': [
        UrlLauncher.MMS_ENTITIES,
      ]
    };
    Log.i(TAG, 'jumpToMms want: %s', JSON.stringify(params));
    // await startAbility() Promise，异常通过 FlutterError 传播具体错误码到 Flutter 层
    try {
      await this.context.startAbility(str);
      Log.i(TAG, 'jumpToMms success.');
      return true;
    } catch (err) {
      let error = err as BusinessError;
      Log.e(TAG, 'jumpToMms failed: %s', JSON.stringify(err));
      throw new FlutterError(
        'LAUNCH_ERROR',
        `Failed to launch sms: ${error.message ?? JSON.stringify(err)}`,
        error.code?.toString() ?? null
      );
    }
  }

  async launchTel(url: string): Promise<boolean> {
    // LAUNCH_TYPE_TEL = 'tel:'，直接作为 prefix 传给 parseUrl 剥离协议前缀
    let phoneNum = this.parseUrl(url, UrlLauncher.LAUNCH_TYPE_TEL);
    if (!phoneNum || phoneNum.trim().length === 0) {
      Log.e(TAG, 'launchTel: phone number is empty, url: %s', url);
      throw new FlutterError('INVALID_URL', 'Phone number is empty', null);
    }
    try {
      phoneNum = decodeURIComponent(phoneNum).replace(/\s+/g, '');
    } catch (e) {
      phoneNum = phoneNum.replace(/\s+/g, '');
    };
    Log.d(TAG, 'launchTel:' + phoneNum);
    // await call.makeCall() Promise，异常通过 FlutterError 传播具体错误码到 Flutter 层
    try {
      await call.makeCall(phoneNum);
      Log.i(TAG, 'launchTel success');
      return true;
    } catch (err) {
      let error = err as BusinessError;
      Log.e(TAG, `launchTel failed, error: ${JSON.stringify(err)}`);
      throw new FlutterError(
        'LAUNCH_ERROR',
        `Failed to make call: ${error.message ?? JSON.stringify(err)}`,
        error.code?.toString() ?? null
      );
    }
  }

  // 只支持沙箱路径
  async launchFile(url: string): Promise<boolean> {
    let fileName = url.substring(url.lastIndexOf('/') + 1);
    if (!fileName || fileName.trim().length === 0) {
      Log.e(TAG, 'launchFile: file name is empty, url: %s', url);
      throw new FlutterError('INVALID_URL', 'File name is empty', null);
    }
    let filePath = this.context.filesDir + '/' + fileName;
    // 将沙箱路径转换为uri（路径非法时 getUriFromPath 会同步抛出 401 参数错误）
    let uriFromPath: string;
    try {
      uriFromPath = fileuri.getUriFromPath(filePath);
    } catch (e) {
      Log.e(TAG, 'launchFile: getUriFromPath failed, path: %s, error: %s', filePath, JSON.stringify(e));
      throw new FlutterError('INVALID_PATH', `Failed to convert path to uri: ${JSON.stringify(e)}`, null);
    }
    Log.d(TAG, 'launchFile url:' + url + '  uriFromPath:' + uriFromPath);
    let want: Want = {
      flags: wantConstant.Flags.FLAG_AUTH_WRITE_URI_PERMISSION | wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION,
      // 配置分享应用的隐式拉起规则
      action: 'ohos.want.action.viewData',
      uri: uriFromPath,
    }
    // await startAbility() Promise，异常通过 FlutterError 传播具体错误码到 Flutter 层
    try {
      await this.context.startAbility(want);
      Log.i(TAG, 'launchFile startAbility succeeded.');
      return true;
    } catch (err) {
      let error = err as BusinessError;
      Log.e(TAG, `launchFile startAbility failed, error: ${JSON.stringify(err)}`);
      throw new FlutterError(
        'LAUNCH_ERROR',
        `Failed to launch file: ${error.message ?? JSON.stringify(err)}`,
        error.code?.toString() ?? null
      );
    }
  }

  async launchWeb(url: string, headers: Map<string, string>): Promise<boolean> {
    // 独立参数验证：与其他子方法风格一致，防止直接调用时无效参数传入
    if (!url || url.trim().length === 0) {
      Log.e(TAG, 'launchWeb: url is empty');
      throw new FlutterError('INVALID_URL', 'URL is empty', null);
    }
    Log.d(TAG, 'launchWeb url:' + url);
    let params: Record<string, Object>  = {};

    for (let val of headers) {
      params[val[0]] = val[1]
    }

    let want: Want = {
      uri: url,
      parameters: params,
      entities: ['entity.system.browsable'],
      action: 'ohos.want.action.viewData',
    }
    // await startAbility() Promise，异常通过 FlutterError 传播具体错误码到 Flutter 层
    try {
      await this.context.startAbility(want);
      Log.i(TAG, 'launchWeb success.');
      return true;
    } catch (err) {
      let error = err as BusinessError;
      Log.e(TAG, `launchWeb failed, error: ${JSON.stringify(err)}`);
      throw new FlutterError(
        'LAUNCH_ERROR',
        `Failed to launch web: ${error.message ?? JSON.stringify(err)}`,
        error.code?.toString() ?? null
      );
    }
  }

  async launchMail(url: string): Promise<boolean> {
    // Want.uri 需完整 mailto: URI 供系统路由，直接使用原始 url
    // （原 parseUrl(url, LAUNCH_TYPE_MAILTO + ':') 拼接为 'mailto::' 无法匹配，且剥离后 Want.uri 缺少协议前缀）
    let mailAddress = url;
    if (!mailAddress || mailAddress.trim().length === 0) {
      Log.e(TAG, 'launchMail: mail address is empty, url: %s', url);
      throw new FlutterError('INVALID_URL', 'Mail address is empty', null);
    }
    let want: Want = {
      uri: mailAddress,
      action: 'ohos.want.action.sendToData',
    }
    // await startAbility() Promise，异常通过 FlutterError 传播具体错误码到 Flutter 层
    try {
      await this.context.startAbility(want);
      Log.i(TAG, 'launchMail success.');
      return true;
    } catch (err) {
      let error = err as BusinessError;
      Log.e(TAG, `launchMail failed, error: ${JSON.stringify(err)}`);
      throw new FlutterError(
        'LAUNCH_ERROR',
        `Failed to launch mail: ${error.message ?? JSON.stringify(err)}`,
        error.code?.toString() ?? null
      );
    }
  }

  /**
   * 跳转到应用商店详情页
   * 文档参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-faqs/faqs-ability-kit#section42001122242
   * @param url
   * @returns
   */
  async launchAppGallery(url: string): Promise<boolean> {
    // 独立参数验证：与其他子方法风格一致，防止直接调用时无效参数传入
    if (!url || url.trim().length === 0) {
      Log.e(TAG, 'launchAppGallery: url is empty');
      throw new FlutterError('INVALID_URL', 'URL is empty', null);
    }
    Log.d(TAG, 'launchAppGallery:' + url);
    //url 格式示范 store://appgallery.huawei.com/app/detail?id=C5765880207855137621
    let want: Want = {
      'action': 'ohos.want.action.appdetail',
      'uri': url,
    };
    // await startAbility() Promise，异常通过 FlutterError 传播具体错误码到 Flutter 层
    try {
      await this.context.startAbility(want);
      Log.i(TAG, 'launchAppGallery success.');
      return true;
    } catch (err) {
      let error = err as BusinessError;
      Log.e(TAG, `launchAppGallery failed, error: ${JSON.stringify(err)}`);
      throw new FlutterError(
        'LAUNCH_ERROR',
        `Failed to launch app gallery: ${error.message ?? JSON.stringify(err)}`,
        error.code?.toString() ?? null
      );
    }
  }

  async launchOther(url: string): Promise<boolean> {
    // 独立参数验证：与其他子方法风格一致，防止直接调用时无效参数传入
    if (!url || url.trim().length === 0) {
      Log.e(TAG, 'launchOther: url is empty');
      throw new FlutterError('INVALID_URL', 'URL is empty', null);
    }
    let want: Want = {
      uri: url,
    }
    // await startAbility() Promise，异常通过 FlutterError 传播具体错误码到 Flutter 层
    try {
      await this.context.startAbility(want);
      Log.i(TAG, 'launchOther success.');
      return true;
    } catch (err) {
      let error = err as BusinessError;
      Log.e(TAG, `launchOther failed, error: ${JSON.stringify(err)}`);
      throw new FlutterError(
        'LAUNCH_ERROR',
        `Failed to launch other: ${error.message ?? JSON.stringify(err)}`,
        error.code?.toString() ?? null
      );
    }
  }

  parseUrl(url: string, prefix: string): string {
    // 严格等号检查，符合 ArkTS 严格模式规范
    if (url === null || url === undefined) {
      return ''
    }
    return url.replace(prefix, '');
  }

  private ensureContext(): void {
    if (this.context === null) {
      throw new FlutterError(
        'NO_ABILITY', 'Launching a URL requires a foreground ability.', null);
    }
  }

  async openUrlInWebView(url: string, options: WebViewOptions, browserOptions: BrowserOptions): Promise<boolean> {
    // 参数验证与其他 launch 方法风格一致，抛出 FlutterError 携带具体错误码
    if (!url || url.trim().length === 0) {
      Log.e(TAG, 'openUrlInWebView: url is empty');
      throw new FlutterError('INVALID_URL', 'URL is empty', null);
    }
    let headers = options.getHeaders();
    if (!headers.has('harmony_browser_page')) {
      promptAction.showToast({
        message: '请在 launch 函数的 headers 参数中添加 harmony_browser_page 和对应的值，并在鸿蒙工程中增加对应的页面和配置路由',
      });
      throw new FlutterError(
        'MISSING_CONFIG',
        'harmony_browser_page is required in headers for in-app WebView',
        null
      );
    }
    let harmonyBrowserPage = headers.get('harmony_browser_page');
    if (!harmonyBrowserPage || harmonyBrowserPage.trim().length === 0) {
      Log.e(TAG, 'openUrlInWebView: harmony_browser_page is empty');
      throw new FlutterError('INVALID_CONFIG', 'harmony_browser_page value is empty', null);
    }

    let headerMap: Record<string, string> = {};
    headers.forEach((value: string, key: string) => {
      if (key !== 'harmony_browser_page') {
        headerMap[key] = value;
      }
    });

    // await router.pushUrl() Promise，异常通过 FlutterError 传播具体错误码到 Flutter 层
    try {
      await router.pushUrl({
        url: harmonyBrowserPage,
        params: {
          'url': url,
          'options': options,
          'headers': headerMap,
          'browserOptions': browserOptions,
        }
      });
      Log.i(TAG, 'openUrlInWebView pushUrl success.');
      return true;
    } catch (err) {
      let businessError = err as BusinessError;
      Log.e(TAG, 'Failed to open url: ', harmonyBrowserPage, ', Error: ', JSON.stringify(businessError));
      if (businessError.code == 100002) {
        promptAction.showToast({
          message: `页面 '${harmonyBrowserPage}' 不存在， 请在鸿蒙工程中创建该页面并注册路由。`,
        });
      }
      throw new FlutterError(
        'LAUNCH_ERROR',
        `Failed to open url in webview: ${businessError.message ?? JSON.stringify(businessError)}`,
        businessError.code?.toString() ?? null
      );
    }
  }

  closeWebView(): void {
    try {
      emitter.emit('closeWebView');
    } catch (e) {
      Log.e(TAG, 'closeWebView emit failed: ' + JSON.stringify(e));
      throw new FlutterError(
        'LAUNCH_ERROR',
        `Failed to close WebView: ${JSON.stringify(e)}`,
        null
      );
    }
  }

  getCodec(): MessageCodec<ESObject> {
    return UrlLauncherApiCodec.INSTANCE;
  }

  setup(binaryMessenger: BinaryMessenger, api: UrlLauncherApi) {
    {
      if (binaryMessenger == null) {
        return;
      }
      let channel: BasicMessageChannel<ESObject> = new BasicMessageChannel<ESObject>(
        binaryMessenger, 'dev.flutter.pigeon.UrlLauncherApi.canLaunchUrl', this.getCodec());
      Log.d(TAG, 'setup launchUrl')
      if (api != null && api != undefined) {
        Log.d(TAG, 'setMessageHandler')
        channel.setMessageHandler({
          onMessage(msg: ESObject, reply: Reply<ESObject>): void {
            let wrapped = new Array<Object>();
            let args = msg as Array<Object>;
            let urlArg: string;
            try {
              if (!args || args.length < 1 || !args[0]) {
                throw new FlutterError('INVALID_ARG', 'canLaunchUrl requires a non-null url argument', null);
              }
              urlArg = args[0] as string;
              let output = api.canLaunchUrl(urlArg);
              wrapped.push(output);
            } catch (err) {
              let errs = wrapError(err);
              wrapped = errs;
            }
            reply.reply(wrapped)
          }
        });
      } else {
        channel.setMessageHandler(null)
      }
    }
    {
      let channel = new BasicMessageChannel<Object>(
        binaryMessenger, 'dev.flutter.pigeon.UrlLauncherApi.launchUrl', this.getCodec());
      Log.d(TAG, 'setup launchUrl')
      if (api != null && api != undefined) {
        Log.d(TAG, 'setMessageHandler')
        channel.setMessageHandler({
          onMessage(msg: ESObject, reply: Reply<ESObject>): void {
            let args = msg as Array<Object>;
            let urlArg: string;
            let headersArg: Map<string, string>;
            try {
              if (!args || args.length < 2 || !args[0]) {
                throw new FlutterError('INVALID_ARG', 'launchUrl requires url and headers arguments', null);
              }
              urlArg = args[0] as string;
              // 过滤 Dart 侧 Map<String?, String?> 可能传入的 null key/value（与 WebViewOptions.setHeaders 一致）
              let rawHeaders = args[1] as Map<string, string>;
              headersArg = new Map<string, string>();
              rawHeaders.forEach((value: string, key: string) => {
                if (key != null && value != null) {
                  headersArg.set(key, value);
                }
              });
            } catch (err) {
              reply.reply(wrapError(err));
              return;
            }
            // launchUrl 返回 Promise<boolean>，异步 resolve 后 reply 实际结果
            api.launchUrl(urlArg, headersArg).then((output: boolean) => {
              let wrapped = new Array<Object>();
              wrapped.push(output);
              reply.reply(wrapped);
            }).catch((err: Error) => {
              reply.reply(wrapError(err));
            });
          }
        });
      } else {
        channel.setMessageHandler(null)
      }
    }
    {
      let channel = new BasicMessageChannel<Object>(
        binaryMessenger, 'dev.flutter.pigeon.UrlLauncherApi.openUrlInWebView', this.getCodec());
      Log.d(TAG, 'setup launchUrl')
      if (api != null && api != undefined) {
        Log.d(TAG, 'setMessageHandler')
        channel.setMessageHandler({
          onMessage(msg: ESObject, reply: Reply<ESObject>): void {
            let args = msg as Array<Object>;
            let urlArg: string;
            let optionsArg: WebViewOptions;
            let browserOptionsArg: BrowserOptions;
            try {
              if (!args || args.length < 3 || !args[0] || !args[1] || !args[2]) {
                throw new FlutterError('INVALID_ARG',
                  'openUrlInWebView requires url, options and browserOptions arguments', null);
              }
              urlArg = args[0] as string;
              optionsArg = args[1] as WebViewOptions;
              browserOptionsArg = args[2] as BrowserOptions;
            } catch (err) {
              reply.reply(wrapError(err));
              return;
            }
            // openUrlInWebView 返回 Promise<boolean>，异步 resolve 后 reply 实际结果
            api.openUrlInWebView(urlArg, optionsArg, browserOptionsArg).then((output: boolean) => {
              let wrapped = new Array<Object>();
              wrapped.push(output);
              reply.reply(wrapped);
            }).catch((err: Error) => {
              reply.reply(wrapError(err));
            });
          }
        });
      } else {
        channel.setMessageHandler(null)
      }
    }
    {
      let channel = new BasicMessageChannel<Object>(
        binaryMessenger, 'dev.flutter.pigeon.UrlLauncherApi.closeWebView', this.getCodec());
      Log.d(TAG, 'setup launchUrl')
      if (api != null && api != undefined) {
        Log.d(TAG, 'setMessageHandler')
        channel.setMessageHandler({
          onMessage(msg: ESObject, reply: Reply<ESObject>): void {
            let wrapped = new Array<Object>();
            try {
              api.closeWebView();
              wrapped.push(null);
            } catch (err) {
              let errs = wrapError(err);
              wrapped = errs;
            }
            reply.reply(wrapped)
          }
        });
      } else {
        channel.setMessageHandler(null)
      }
    }
  }
}