// Copyright (c) 2024 Huawei Device Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_HW file.
// Based on CameraPropertiesImpl.java originally written by
// Copyright 2013 The Flutter Authors.

import { CameraProperties } from './CameraProperties';
import { camera } from '@kit.CameraKit';
import { CameraUtils } from './CameraUtils';

export class CameraPropertiesImpl implements CameraProperties {
  private cameraName: string;
  private cameraDevice: camera.CameraDevice | null;

  constructor(cameraName: string, cameraManager: camera.CameraManager) {
    this.cameraName = cameraName;
    this.cameraDevice = CameraUtils.getCameraDevice(cameraName, cameraManager);

    // 如果获取相机设备失败，抛出错误
    if (!this.cameraDevice) {
      throw new Error(`无法获取相机设备: ${cameraName}`);
    }
  }

  getCameraName(): string {
    return this.cameraName;
  }

  // 曝光点能力上报：此值为固定常量 1，表示设备最大测光区域数（能力上限），并非设
  // 备查询结果。
  // OHOS Camera Kit 支持 AutoExposure.setMeteringPoint 单点测光，故恒返回 1
  // 使 exposurePointSupported 上报为 true。
  // 对照 Android：CameraPropertiesImpl.java 通过 CONTROL_MAX_REGIONS_AE 查询，主流设备该值同为 1。
  getControlMaxRegionsAutoExposure(): number {
    return 1;
  }

  // 对焦点能力上报：此值为固定常量 1，表示设备最大对焦区域数（能力上限），并非设
  // 备查询结果。
  // OHOS Camera Kit 支持 Focus.setFocusPoint 单点对焦，故恒返回 1
  // 使 focusPointSupported 上报为 true。
  // 对照 Android：CameraPropertiesImpl.java 通过 CONTROL_MAX_REGIONS_AF 查询，主流设备该值同为 1。
  getControlMaxRegionsAutoFocus(): number {
    return 1;
  }

  // 镜头朝向：返回 Camera Kit CameraPosition 枚举数值
  // （CAMERA_POSITION_UNSPECIFIED=0 / BACK=1 / FRONT=2 / FOLD_INNER=3）。
  //
  // ⚠️ 该数值与 Android CameraMetadata.LENS_FACING（FRONT=0 / BACK=1 / EXTERNAL=2）不兼容：
  // FRONT 在两侧分别为 2 与 0，UNSPECIFIED(0) 与 Android FRONT(0) 数值重叠。该值仅供 OHOS
  // 平台内部消费——SensorOrientationFeature 以 `== CAMERA_POSITION_FRONT` 判断前摄，
  // Camera.ets 录像时记录初始朝向（initialCameraFacing，当前仅赋值未读取）。
  // 不得将此原始值作为 Android 语义的 lensFacing 序列化跨端；跨端 lensDirection 由
  // CameraUtils.getAvailableCameras 显式映射为 'front'/'back'/'external' 字符串。
  getLensFacing(): number {
    return this.cameraDevice?.cameraPosition ?? 0;
  }

  // 传感器安装方向角（0~360°，随屏幕旋转不变），等价于 Android SENSOR_ORIENTATION，
  // 参与 DeviceOrientationManager 的照片/视频方向计算。
  getSensorOrientation(): number {
    return this.cameraDevice?.cameraOrientation ?? 0;
  }
}
