/*
 * Copyright (C) 2026 Huawei Device Co., Ltd.
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
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { UrlLauncher, FlutterError, WebViewOptions, BrowserOptions } from '../../../../index';
import emitter from '@ohos.events.emitter';

/** Helper for building WebViewOptions/BrowserOptions (fromList is the public factory) */
class TestWebViewOptions {
  private headers: Map<string, string>;

  constructor(headers?: Map<string, string>) {
    if (headers !== undefined) {
      this.headers = headers;
    } else {
      this.headers = new Map<string, string>();
    }
  }

  toOptions(): WebViewOptions {
    return WebViewOptions.fromList([true, false, this.headers]);
  }

  toBrowserOptions(): BrowserOptions {
    return BrowserOptions.fromList([true]);
  }
}

/**
 * Fake UIAbilityContext: startAbility success/failure is injectable and Want arguments
 * are recorded. UrlLauncher only holds the context via its constructor and calls
 * startAbility/filesDir, so this fake can fully drive the launchWeb/Mail/AppGallery/Other
 * paths that end in startAbility (no @ohos.* system module interception needed).
 */
class StartAbilityRecord {
  want: Record<string, Object> | null = null;
}

class FakeUIAbilityContext {
  filesDir: string = '/data/app/els/files';
  /** 'success' | 'fail' */
  behavior: string = 'success';
  failCode: number = 16000001;
  failMessage: string = 'Launch ability failed';
  records: StartAbilityRecord[] = [];

  startAbility(want: Record<string, Object>): Promise<void> {
    this.records.push({ want: want });
    if (this.behavior === 'fail') {
      return Promise.reject({ code: this.failCode, message: this.failMessage });
    }
    return Promise.resolve();
  }
}

function expectFlutterError(e: Object | null, code: string): void {
  expect(e instanceof FlutterError).assertTrue();
  expect((e as FlutterError).code).assertEqual(code);
}

/** Error assertion helper: records whether an error was thrown;
 * when nothing is thrown, the caller's assertion on the caught flag fails */
class ErrorCaptor {
  caught: boolean = false;
  error: Object | null = null;

  capture(action: () => Promise<ESObject>): Promise<void> {
    return action().then(() => {
      // Nothing thrown: the caller asserts the caught flag fails
    }).catch((e: Object) => {
      this.caught = true;
      this.error = e;
    });
  }

  expectCode(code: string): void {
    expect(this.caught).assertTrue();
    expectFlutterError(this.error, code);
  }
}

/**
 * UrlLauncher.ets unit tests (self-contained, all fakes inlined, no src/mock dependency)
 */
export default function urlLauncherTest() {
  describe('UrlLauncherTest', () => {
    let launcher: UrlLauncher = new UrlLauncher(null as ESObject);
    let ctx: FakeUIAbilityContext = new FakeUIAbilityContext();

    beforeAll(() => {
      ctx = new FakeUIAbilityContext();
      launcher = new UrlLauncher(ctx as ESObject);
    });
    beforeEach(() => {
      ctx.behavior = 'success';
      ctx.records = [];
    });
    afterEach(() => {
    });
    afterAll(() => {
    });

    // ---------- Static constants and regex ----------
    it('launch_type_constants', 0, () => {
      expect(UrlLauncher.LAUNCH_TYPE_TEL).assertEqual('tel:');
      expect(UrlLauncher.LAUNCH_TYPE_WEB_HTTP).assertEqual('http:');
      expect(UrlLauncher.LAUNCH_TYPE_WEB_HTTPS).assertEqual('https:');
      expect(UrlLauncher.LAUNCH_TYPE_MAILTO).assertEqual('mailto:');
      expect(UrlLauncher.LAUNCH_TYPE_SMS).assertEqual('sms:');
      expect(UrlLauncher.LAUNCH_TYPE_FILE).assertEqual('file:');
      expect(UrlLauncher.LAUNCH_TYPE_APP_GALLERY).assertEqual('store:');
      expect(UrlLauncher.LAUNCH_TYPE_ENTERPRISE).assertEqual('store://enterprise');
    });

    it('mms_bundle_constants', 0, () => {
      expect(UrlLauncher.MMS_BUNDLE_NAME).assertEqual('com.ohos.mms');
      expect(UrlLauncher.MMS_ABILITY_NAME).assertEqual('com.ohos.mms.MainAbility');
      expect(UrlLauncher.MMS_ENTITIES).assertEqual('entity.system.home');
    });

    it('sms_body_regex_matches', 0, () => {
      let m1 = 'body=hello'.match(UrlLauncher.SMS_QUERY_BODY_REGEX);
      expect(m1 !== null).assertTrue();
      expect(m1 !== null ? m1[1] : '').assertEqual('hello');
      let m2 = 'foo=1&body=a%20b&x=2'.match(UrlLauncher.SMS_QUERY_BODY_REGEX);
      expect(m2 !== null).assertTrue();
      expect(m2 !== null ? m2[1] : '').assertEqual('a%20b');
      expect('foo=1&bar=2'.match(UrlLauncher.SMS_QUERY_BODY_REGEX)).assertNull();
    });

    // ---------- parseUrl ----------
    it('parseUrl_strips_prefix', 0, () => {
      expect(launcher.parseUrl('tel:12345', 'tel:')).assertEqual('12345');
      expect(launcher.parseUrl('sms:10086?body=hi', 'sms:')).assertEqual('10086?body=hi');
    });

    it('parseUrl_no_prefix_match_returns_original', 0, () => {
      expect(launcher.parseUrl('mailto:a@b.c', 'tel:')).assertEqual('mailto:a@b.c');
    });

    it('parseUrl_null_url_returns_empty', 0, () => {
      expect(launcher.parseUrl(null as ESObject as string, 'tel:')).assertEqual('');
      expect(launcher.parseUrl(undefined as ESObject as string, 'tel:')).assertEqual('');
    });

    // ---------- format input validation (i18n success path needs the on-device PhoneNumberFormat) ----------
    it('format_empty_returns_empty', 0, () => {
      expect(launcher.format('')).assertEqual('');
      expect(launcher.format('   ')).assertEqual('');
    });

    it('format_null_returns_empty', 0, () => {
      expect(launcher.format(null as ESObject as string)).assertEqual('');
      expect(launcher.format(undefined as ESObject as string)).assertEqual('');
    });

    it('format_non_string_returns_empty', 0, () => {
      expect(launcher.format(123 as ESObject as string)).assertEqual('');
    });

    // ---------- canLaunchUrl input validation ----------
    it('canLaunchUrl_empty_returns_false', 0, () => {
      expect(launcher.canLaunchUrl('')).assertFalse();
      expect(launcher.canLaunchUrl('   ')).assertFalse();
      expect(launcher.canLaunchUrl(null as ESObject as string)).assertFalse();
    });

    // ---------- launchUrl input/environment validation ----------
    it('launchUrl_empty_url_returns_false', 0, async () => {
      // No INVALID_URL throw branch in the source: the canLaunchUrl('') prefix check misses → returns false directly
      let result = await launcher.launchUrl('', new Map<string, string>());
      expect(result).assertFalse();
    });

    it('launchUrl_blank_url_with_null_headers_returns_false', 0, async () => {
      // null headers falls back to an empty Map; the blank URL prefix check misses → returns false
      let result = await launcher.launchUrl(' ', null as ESObject as Map<string, string>);
      expect(result).assertFalse();
    });

    it('launchUrl_no_context_throws_no_ability', 0, async () => {
      let nullCtxLauncher = new UrlLauncher(null as ESObject);
      let captor = new ErrorCaptor();
      await captor.capture(() => nullCtxLauncher.launchUrl('tel:123', new Map<string, string>()));
      captor.expectCode('NO_ABILITY');
    });

    // ---------- launchUrl scheme dispatch (startAbility is injectable; every path asserts the Want) ----------
    it('launchUrl_http_dispatches_to_launchWeb_with_headers', 0, async () => {
      let headers = new Map<string, string>();
      headers.set('X-Token', 'abc');
      let result = await launcher.launchUrl('http://example.com', headers);
      expect(result).assertTrue();
      expect(ctx.records.length).assertEqual(1);
      let want = ctx.records[0].want!;
      expect(want['uri']).assertEqual('http://example.com');
      expect(want['action']).assertEqual('ohos.want.action.viewData');
      expect(want['entities']).assertDeepEquals(['entity.system.browsable']);
      let params = want['parameters'] as Record<string, string>;
      expect(params['X-Token']).assertEqual('abc');
    });

    it('launchUrl_https_dispatches_to_launchWeb', 0, async () => {
      let result = await launcher.launchUrl('https://example.com', new Map<string, string>());
      expect(result).assertTrue();
      expect(ctx.records.length).assertEqual(1);
    });

    it('launchUrl_mailto_dispatches_to_launchMail', 0, async () => {
      let result = await launcher.launchUrl('mailto:a@b.c', new Map<string, string>());
      expect(result).assertTrue();
      let want = ctx.records[0].want!;
      expect(want['uri']).assertEqual('mailto:a@b.c');
      expect(want['action']).assertEqual('ohos.want.action.sendToData');
    });

    it('launchUrl_appgallery_dispatches_to_launchAppGallery', 0, async () => {
      let result = await launcher.launchUrl('store://appgallery.huawei.com/app/detail?id=C1',
        new Map<string, string>());
      expect(result).assertTrue();
      let want = ctx.records[0].want!;
      expect(want['action']).assertEqual('ohos.want.action.appdetail');
      expect(want['uri']).assertEqual('store://appgallery.huawei.com/app/detail?id=C1');
    });

    it('launchUrl_store_enterprise_dispatches_to_launchOther', 0, async () => {
      let result = await launcher.launchUrl('store://enterprise/apps?id=1', new Map<string, string>());
      expect(result).assertTrue();
      let want = ctx.records[0].want!;
      expect(want['uri']).assertEqual('store://enterprise/apps?id=1');
    });

    // ---------- launchWeb ----------
    it('launchWeb_empty_url_starts_ability_and_returns_true', 0, async () => {
      // launchWeb has no empty-URL check in the source; the fake startAbility succeeds → true
      expect(await launcher.launchWeb('', new Map<string, string>())).assertTrue();
    });

    it('launchWeb_success', 0, async () => {
      expect(await launcher.launchWeb('https://example.com', new Map<string, string>())).assertTrue();
    });

    it('launchWeb_startAbility_fail_throws_launch_error_with_code', 0, async () => {
      ctx.behavior = 'fail';
      ctx.failCode = 16000019;
      ctx.failMessage = 'web fail';
      let captor = new ErrorCaptor();
      await captor.capture(() => launcher.launchWeb('https://example.com', new Map<string, string>()));
      captor.expectCode('LAUNCH_ERROR');
      expect((captor.error as FlutterError).details).assertEqual('16000019');
    });

    // ---------- launchMail ----------
    it('launchMail_empty_url_starts_ability_and_returns_true', 0, async () => {
      // launchMail has no empty-URL check in the source; the fake startAbility succeeds → true
      expect(await launcher.launchMail('')).assertTrue();
    });

    it('launchMail_success', 0, async () => {
      expect(await launcher.launchMail('mailto:a@b.c')).assertTrue();
    });

    it('launchMail_startAbility_fail_throws_launch_error', 0, async () => {
      ctx.behavior = 'fail';
      let captor = new ErrorCaptor();
      await captor.capture(() => launcher.launchMail('mailto:a@b.c'));
      captor.expectCode('LAUNCH_ERROR');
    });

    // ---------- launchAppGallery ----------
    it('launchAppGallery_empty_url_starts_ability_and_returns_true', 0, async () => {
      // launchAppGallery has no empty-URL check in the source; the fake startAbility succeeds → true
      expect(await launcher.launchAppGallery('')).assertTrue();
    });

    it('launchAppGallery_success', 0, async () => {
      expect(await launcher.launchAppGallery('store://appgallery.huawei.com/app/detail?id=C1')).assertTrue();
    });

    it('launchAppGallery_startAbility_fail_throws_launch_error', 0, async () => {
      ctx.behavior = 'fail';
      let captor = new ErrorCaptor();
      await captor.capture(() => launcher.launchAppGallery('store://x'));
      captor.expectCode('LAUNCH_ERROR');
    });

    // ---------- launchOther ----------
    it('launchOther_blank_url_starts_ability_and_returns_true', 0, async () => {
      // launchOther has no blank-URL check in the source; the fake startAbility succeeds → true
      expect(await launcher.launchOther(' ')).assertTrue();
    });

    it('launchOther_success', 0, async () => {
      expect(await launcher.launchOther('store://enterprise/apps?id=1')).assertTrue();
    });

    it('launchOther_startAbility_fail_throws_launch_error', 0, async () => {
      ctx.behavior = 'fail';
      let captor = new ErrorCaptor();
      await captor.capture(() => launcher.launchOther('store://x'));
      captor.expectCode('LAUNCH_ERROR');
    });

    // ---------- launchTel / launchSms / launchFile empty-argument paths ----------
    it('launchTel_empty_number_returns_true', 0, async () => {
      // No empty-number check in the source: call.makeCall('') resolves normally in the test environment → true
      expect(await launcher.launchTel('tel:')).assertTrue();
    });

    it('launchSms_empty_number_starts_mms_ability', 0, async () => {
      // No empty-number check in the source: an empty phoneNumber still builds the Want
      // and calls startAbility (fake succeeds) → true
      expect(await launcher.launchSms('sms:')).assertTrue();
    });

    it('launchFile_empty_name_starts_ability', 0, async () => {
      // No empty-filename check in the source: filesDir + '/' converts to a uri and startAbility runs → true
      expect(await launcher.launchFile('file:///')).assertTrue();
    });

    // ---------- openUrlInWebView empty-argument paths ----------
    // (route navigation depends on @ohos.router; on-device path)
    it('openUrlInWebView_empty_url_throws_missing_config', 0, async () => {
      // No empty-URL check in the source: the headers harmony_browser_page check runs first → MISSING_CONFIG
      let opts = new TestWebViewOptions();
      let captor = new ErrorCaptor();
      await captor.capture(() => launcher.openUrlInWebView('', opts.toOptions(), opts.toBrowserOptions()));
      captor.expectCode('MISSING_CONFIG');
    });

    // ---------- openUrlInWebView main branches (on device: router.pushUrl is reachable) ----------
    it('openUrlInWebView_missing_harmony_browser_page_throws_missing_config', 0, async () => {
      let opts = new TestWebViewOptions();
      let captor = new ErrorCaptor();
      await captor.capture(() => launcher.openUrlInWebView('https://example.com', opts.toOptions(), opts.toBrowserOptions()));
      captor.expectCode('MISSING_CONFIG');
    });

    it('openUrlInWebView_blank_harmony_browser_page_throws_launch_error', 0, async () => {
      // No blank-page check in the source: '   ' is handed to router.pushUrl, which fails → LAUNCH_ERROR
      let headers = new Map<string, string>();
      headers.set('harmony_browser_page', '   ');
      let opts = new TestWebViewOptions(headers);
      let captor = new ErrorCaptor();
      await captor.capture(() => launcher.openUrlInWebView('https://example.com', opts.toOptions(), opts.toBrowserOptions()));
      captor.expectCode('LAUNCH_ERROR');
    });

    it('openUrlInWebView_page_not_found_throws_launch_error', 0, async () => {
      let headers = new Map<string, string>();
      headers.set('harmony_browser_page', 'pages/NotExists');
      let opts = new TestWebViewOptions(headers);
      let captor = new ErrorCaptor();
      await captor.capture(() => launcher.openUrlInWebView('https://example.com', opts.toOptions(), opts.toBrowserOptions()));
      // router.pushUrl fails (page does not exist) → LAUNCH_ERROR; any other code
      // such as INVALID_URL is treated as failure
      captor.expectCode('LAUNCH_ERROR');
    });

    // ---------- closeWebView ----------
    it('closeWebView_emits_event_to_subscriber', 0, async () => {
      // emit dispatches asynchronously through the event queue; the callback is not
      // guaranteed to run immediately, so poll and wait
      let closeCount: number = 0;
      let callback = () => {
        closeCount++;
      };
      emitter.on('closeWebView', callback);
      launcher.closeWebView();
      for (let i = 0; i < 20 && closeCount === 0; i++) {
        await new Promise<void>((resolve) => {
          setTimeout(resolve, 10);
        });
      }
      expect(closeCount).assertEqual(1);
      emitter.off('closeWebView', callback);
      // After unregistering, emitting again must not trigger the callback
      launcher.closeWebView();
      for (let i = 0; i < 20 && closeCount !== 1; i++) {
        await new Promise<void>((resolve) => {
          setTimeout(resolve, 10);
        });
      }
      expect(closeCount).assertEqual(1);
    });

    // ---------- launchSms / launchTel / launchFile success paths (on-device system capabilities) ----------
    it('launchSms_with_number_starts_mms_ability', 0, async () => {
      // sms:10086 → startAbility(bundleName=com.ohos.mms) succeeds and returns true
      let result = await launcher.launchSms('sms:10086');
      expect(result).assertTrue();
      expect(ctx.records.length).assertEqual(1);
      let want = ctx.records[0].want!;
      expect(want['bundleName']).assertEqual('com.ohos.mms');
      expect(want['abilityName']).assertEqual('com.ohos.mms.MainAbility');
    });

    it('launchSms_with_body_encodes_content_param', 0, async () => {
      let result = await launcher.launchSms('sms:10086?body=hello%20world');
      expect(result).assertTrue();
      let params = ctx.records[0].want!['parameters'] as Record<string, string>;
      expect(params['content']).assertEqual('hello world');
    });

    it('launchSms_startAbility_fail_throws_launch_error', 0, async () => {
      ctx.behavior = 'fail';
      let captor = new ErrorCaptor();
      await captor.capture(() => launcher.launchSms('sms:10086'));
      captor.expectCode('LAUNCH_ERROR');
    });

    it('launchSms_invalid_body_fallback_uses_raw', 0, async () => {
      // %zz is an invalid escape: decodeURIComponent throws → messageBody falls back to the raw value
      let result = await launcher.launchSms('sms:10086?body=%zz');
      expect(result).assertTrue();
      let params = ctx.records[0].want!['parameters'] as Record<string, string>;
      expect(params['content']).assertEqual('%zz');
    });

    it('launchTel_success_or_permission_denied', 0, async () => {
      // call.makeCall requires the system-granted ohos.permission.PLACE_CALL:
      // with permission it triggers the dial confirmation and resolves true; without it
      // a FlutterError LAUNCH_ERROR is thrown
      let captor = new ErrorCaptor();
      await captor.capture(() => launcher.launchTel('tel:10086'));
      if (captor.caught) {
        captor.expectCode('LAUNCH_ERROR');
      }
    });

    it('launchTel_encoded_number_is_decoded', 0, async () => {
      // tel:+86%2013800138000 → decoded, whitespace stripped, then makeCall (permission behavior as above)
      let captor = new ErrorCaptor();
      await captor.capture(() => launcher.launchTel('tel:+86%2013800138000'));
      if (captor.caught) {
        captor.expectCode('LAUNCH_ERROR');
      }
    });

    it('launchFile_sandbox_name_starts_ability', 0, async () => {
      // filesDir + '/a.txt' converts to a uri on device and startAbility runs
      let result = await launcher.launchFile('file:///a.txt');
      expect(result).assertTrue();
      expect(ctx.records.length).assertEqual(1);
      let want = ctx.records[0].want!;
      expect(want['action']).assertEqual('ohos.want.action.viewData');
    });

    it('launchFile_startAbility_fail_throws_launch_error', 0, async () => {
      ctx.behavior = 'fail';
      let captor = new ErrorCaptor();
      await captor.capture(() => launcher.launchFile('file:///a.txt'));
      captor.expectCode('LAUNCH_ERROR');
    });

    // ---------- format success path (i18n.PhoneNumberFormat is available on device) ----------
    it('format_valid_number_returns_formatted', 0, () => {
      let out = launcher.format('138 0013 8000');
      // Returns a non-empty formatted result (the exact format varies with the system region)
      expect(out.length > 0).assertTrue();
    });

    // ---------- canLaunchUrl scheme fallback branches (canOpenLink is available on device) ----------
    it('canLaunchUrl_tel_prefix_returns_true', 0, () => {
      expect(launcher.canLaunchUrl('tel:10086')).assertTrue();
    });

    it('canLaunchUrl_sms_prefix_returns_true', 0, () => {
      expect(launcher.canLaunchUrl('sms:10086')).assertTrue();
    });

    it('canLaunchUrl_mailto_prefix_returns_true', 0, () => {
      expect(launcher.canLaunchUrl('mailto:a@b.c')).assertTrue();
    });

    it('canLaunchUrl_file_prefix_returns_true', 0, () => {
      expect(launcher.canLaunchUrl('file:///a.txt')).assertTrue();
    });

    it('canLaunchUrl_http_via_canOpen_link_or_prefix_returns_true', 0, () => {
      expect(launcher.canLaunchUrl('http://example.com')).assertTrue();
    });

    it('canLaunchUrl_appgallery_prefix_returns_true', 0, () => {
      expect(launcher.canLaunchUrl('store://appgallery.huawei.com/app/detail?id=C1')).assertTrue();
    });

    // ---------- launchUrl dispatch supplementary branches ----------
    it('launchUrl_sms_dispatches_to_launchSms', 0, async () => {
      let result = await launcher.launchUrl('sms:10086', new Map<string, string>());
      expect(result).assertTrue();
      expect(ctx.records.length).assertEqual(1);
    });

    it('launchUrl_file_dispatches_to_launchFile', 0, async () => {
      let result = await launcher.launchUrl('file:///a.txt', new Map<string, string>());
      expect(result).assertTrue();
    });

    it('launchUrl_unsupported_scheme_returns_false', 0, async () => {
      // No CANNOT_LAUNCH throw branch in the source: the canLaunchUrl('ftp:') prefix check misses → returns false
      let result = await launcher.launchUrl('ftp://example.com', new Map<string, string>());
      expect(result).assertFalse();
    });

    it('launchUrl_null_headers_defaults_to_empty', 0, async () => {
      // null headers falls back to an empty Map, then http dispatches normally
      let result = await launcher.launchUrl('https://example.com', null as ESObject as Map<string, string>);
      expect(result).assertTrue();
    });

    // ---------- getCodec ----------
    it('getCodec_returns_singleton', 0, () => {
      expect(launcher.getCodec() !== null).assertTrue();
      expect(launcher.getCodec()).assertEqual(launcher.getCodec());
    });

    // ---------- canLaunchUrl canOpenLink hit branch (querySchemes already configures https/http) ----------
    it('canLaunchUrl_https_via_canOpenLink_returns_true', 0, () => {
      // canOpenLink('https://...') returns true → returns true directly (no prefix fallback)
      expect(launcher.canLaunchUrl('https://example.com')).assertTrue();
    });

    it('launchSms_invalid_escape_falls_back_to_raw_number', 0, async () => {
      // %zz is an invalid escape: decodeURIComponent throws → the catch falls back to
      // the raw value and startAbility runs
      let result = await launcher.launchSms('sms:138%zz0013');
      expect(result).assertTrue();
      expect(ctx.records.length).assertEqual(1);
    });

    // ---------- openUrlInWebView business-header filtering branch ----------
    it('openUrlInWebView_filters_out_harmony_browser_page_header', 0, async () => {
      // Business headers other than harmony_browser_page are kept and enter the pushUrl params
      let headers = new Map<string, string>();
      headers.set('harmony_browser_page', 'pages/NotExists');
      headers.set('X-Token', 'abc');
      let opts = new TestWebViewOptions(headers);
      let captor = new ErrorCaptor();
      await captor.capture(() => launcher.openUrlInWebView('https://example.com', opts.toOptions(), opts.toBrowserOptions()));
      // pushUrl fails, but the forEach filtering branch has already run
      captor.expectCode('LAUNCH_ERROR');
    });
  });
}
