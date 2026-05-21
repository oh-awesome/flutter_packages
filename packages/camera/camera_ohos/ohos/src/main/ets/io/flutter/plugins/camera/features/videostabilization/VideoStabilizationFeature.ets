/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import camera from '@ohos.multimedia.camera';
import { CameraProperties } from '../../CameraProperties';
import { CameraFeature } from '../CameraFeature';
import { PlatformVideoStabilizationMode } from '../../Messages';

/**
 * 视频防抖特性管理类，负责处理相机视频防抖的设置与查询
 */
export class VideoStabilizationFeature extends CameraFeature<PlatformVideoStabilizationMode> {
  // 当前设置的防抖模式，默认为关闭
  private currentSetting: PlatformVideoStabilizationMode = PlatformVideoStabilizationMode.off;

  /**
   * 构造函数，初始化防抖特性
   * @param cameraProperties 相机属性对象
   */
  constructor(cameraProperties: CameraProperties) {
    super(cameraProperties);
  }

  /**
   * 获取特性的调试名称
   * @returns 调试名称字符串
   */
  public getDebugName(): string {
    return 'VideoStabilizationFeature';
  }

  /**
   * 获取当前设置的防抖模式
   * @returns 当前的 PlatformVideoStabilizationMode
   */
  public getValue(): PlatformVideoStabilizationMode {
    return this.currentSetting;
  }

  /**
   * 设置新的防抖模式
   * @param value 要设置的 PlatformVideoStabilizationMode
   */
  public setValue(value: PlatformVideoStabilizationMode): void {
    this.currentSetting = value;
  }

  /**
   * 检查该特性是否被支持（动态按模式检查）
   * @returns 始终返回 true，具体支持情况在更新时判断
   */
  public checkIsSupported(): boolean {
    return true; 
  }

  /**
   * 更新相机 Session，将防抖设置应用到原生 VideoSession 中
   * @param session 当前的相机 Session (必须是 VideoSession)
   */
  public updateBuilder(session: camera.Session): void {
    console.log('VideoStabilizationFeature', `VideoStabilizationFeature.ets - updateBuilder called`);

    try {
      let videoSession = session as camera.VideoSession;
      let ohosMode = this.toOhosVideoStabilizationMode(this.currentSetting);
      console.log('VideoStabilizationFeature', `VideoStabilizationFeature.ets - applying mode ${this.currentSetting}, ohosMode: ${ohosMode}`);
      // 检查当前设备是否支持该防抖模式，不支持则依次兜底
      let finalMode = ohosMode;
      if (!videoSession.isVideoStabilizationModeSupported(finalMode)) {
        console.warn('VideoStabilizationFeature', `当前设备不支持视频防抖模式: ${this.currentSetting} (OHOS: ${ohosMode})，尝试使用AUTO模式兜底`);
        finalMode = camera.VideoStabilizationMode.AUTO;
        // 检查AUTO模式是否支持，不支持则使用OFF模式兜底
        if (!videoSession.isVideoStabilizationModeSupported(finalMode)) {
          console.warn('VideoStabilizationFeature', `当前设备也不支持AUTO防抖模式，使用OFF模式兜底`);
          finalMode = camera.VideoStabilizationMode.OFF;
        }
      }
      // 应用最终确定的防抖模式
      videoSession.setVideoStabilizationMode(finalMode);
      console.log('VideoStabilizationFeature', `VideoStabilizationFeature.ets - successfully applied mode ${finalMode}`);
    } catch (e) {
      console.error(`设置视频防抖模式失败: ${e}`);
    }
  }

  /**
   * 查询当前设备支持的所有视频防抖模式
   * @param session 当前的相机 VideoSession
   * @returns 支持的 PlatformVideoStabilizationMode 数组
   */
  public getSupportedModes(): PlatformVideoStabilizationMode[] {
    console.log('VideoStabilizationFeature', `VideoStabilizationFeature.ets - getSupportedModes called`);
    // 直接返回所有支持的防抖模式，不依赖session判断
    return [
      PlatformVideoStabilizationMode.off,
      PlatformVideoStabilizationMode.level1,
      PlatformVideoStabilizationMode.level2,
      PlatformVideoStabilizationMode.level3
    ];
  }

  /**
   * 将 Platform 枚举转换为 OHOS 原生的 VideoStabilizationMode 枚举
   * @param mode Flutter 侧传递的防抖模式
   * @returns OHOS 原生相机防抖模式
   */
  private toOhosVideoStabilizationMode(mode: PlatformVideoStabilizationMode): camera.VideoStabilizationMode {
    switch (mode) {
      case PlatformVideoStabilizationMode.off:
        return camera.VideoStabilizationMode.OFF;
      case PlatformVideoStabilizationMode.level1:
        return camera.VideoStabilizationMode.LOW;
      case PlatformVideoStabilizationMode.level2:
        return camera.VideoStabilizationMode.MIDDLE;
      case PlatformVideoStabilizationMode.level3:
        return camera.VideoStabilizationMode.HIGH;
      default:
        return camera.VideoStabilizationMode.OFF;
    }
  }
}
