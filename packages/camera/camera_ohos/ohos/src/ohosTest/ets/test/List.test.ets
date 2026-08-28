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

// Aggregates all camera_ohos ArkTS unit test suites for the hypium runner.

import pureTypesAndEnumsTest from './PureTypesAndEnums.test';
import modeConversionsTest from './ModeConversions.test';
import fpsRangeFeatureTest from './FpsRangeFeature.test';
import featuresSetGetTest from './FeaturesSetGet.test';
import cameraFeaturesMapTest from './CameraFeaturesMap.test';
import cameraMessagesDataClassTest from './CameraMessagesDataClass.test';
import resolutionFeatureTest from './ResolutionFeature.test';
import orientationAndMessengerTest from './OrientationAndMessenger.test';
import cameraPropertiesImplTest from './CameraPropertiesImpl.test';
import cameraPluginLifecycleTest from './CameraPluginLifecycle.test';
import cameraUtilsQueriesTest from './CameraUtilsQueries.test';
import imageStreamReaderTest from './ImageStreamReader.test';
import cameraApiImplGuardsTest from './CameraApiImplGuards.test';
import cameraLifecycleTest from './CameraLifecycle.test';
import pigeonDispatchTest from './PigeonDispatch.test';
import cameraSessionMethodsTest from './CameraSessionMethods.test';
import cameraApiImplDelegatedTest from './CameraApiImplDelegated.test';

export default function testsuite() {
  pureTypesAndEnumsTest();
  modeConversionsTest();
  fpsRangeFeatureTest();
  featuresSetGetTest();
  cameraFeaturesMapTest();
  cameraMessagesDataClassTest();
  resolutionFeatureTest();
  orientationAndMessengerTest();
  cameraPropertiesImplTest();
  cameraPluginLifecycleTest();
  cameraUtilsQueriesTest();
  imageStreamReaderTest();
  cameraApiImplGuardsTest();
  cameraLifecycleTest();
  pigeonDispatchTest();
  cameraSessionMethodsTest();
  cameraApiImplDelegatedTest();
}
