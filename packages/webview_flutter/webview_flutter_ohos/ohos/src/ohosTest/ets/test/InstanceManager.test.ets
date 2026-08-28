/*
 * Copyright (C) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 *
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
 
// InstanceManager 单元测试：覆盖实例注册、标识符分配、移除、清理与异常分支。

import { describe, it, expect } from '@ohos/hypium';
import { InstanceManager } from '../../../main/ets/io.flutter.plugins/webview_flutter/InstanceManager';

class Marker {
}

function newManager(): InstanceManager {
  return new InstanceManager({
    onFinalize: (identifier: number): void => {
    }
  });
}

export default function instanceManagerTest() {
  describe('InstanceManagerTest', () => {
    it('hostCreatedIdentifiersStartAt65536', 0, () => {
      const manager: InstanceManager = newManager();
      const first: Marker = new Marker();
      const second: Marker = new Marker();
      const id1: number = manager.addHostCreatedInstance(first);
      const id2: number = manager.addHostCreatedInstance(second);
      expect(id1).assertEqual(65536);
      expect(id2).assertEqual(65537);
      expect(manager.getIdentifier(first)).assertEqual(id1);
      expect(manager.getIdentifier(second)).assertEqual(id2);
    })

    it('dartCreatedInstanceUsesGivenIdentifier', 0, () => {
      const manager: InstanceManager = newManager();
      const instance: Marker = new Marker();
      manager.addDartCreatedInstance(instance, 3);
      expect(manager.getIdentifier(instance)).assertEqual(3);
      expect(manager.getInstance(3)).assertEqual(instance);
      expect(manager.containsInstance(instance)).assertTrue();
    })

    it('getIdentifierReturnsMinusOneForUnknownInstance', 0, () => {
      const manager: InstanceManager = newManager();
      expect(manager.getIdentifier(new Marker())).assertEqual(-1);
    })

    it('getInstanceReturnsUndefinedForUnknownIdentifier', 0, () => {
      const manager: InstanceManager = newManager();
      expect(manager.getInstance(12345)).assertUndefined();
    })

    it('containsInstanceReturnsFalseForUnknownInstance', 0, () => {
      const manager: InstanceManager = newManager();
      expect(manager.containsInstance(new Marker())).assertFalse();
    })

    it('duplicateHostCreatedInstanceThrows', 0, () => {
      const manager: InstanceManager = newManager();
      const instance: Marker = new Marker();
      manager.addHostCreatedInstance(instance);
      let threw: boolean = false;
      let message: string = '';
      try {
        manager.addHostCreatedInstance(instance);
      } catch (err) {
        threw = true;
        message = `${err}`;
      }
      expect(threw).assertTrue();
      expect(message.includes('has already been added')).assertTrue();
    })

    it('negativeDartIdentifierThrows', 0, () => {
      const manager: InstanceManager = newManager();
      let threw: boolean = false;
      let message: string = '';
      try {
        manager.addDartCreatedInstance(new Marker(), -1);
      } catch (err) {
        threw = true;
        message = `${err}`;
      }
      expect(threw).assertTrue();
      expect(message.includes('Identifier must be >= 0')).assertTrue();
    })

    it('duplicateDartIdentifierThrows', 0, () => {
      const manager: InstanceManager = newManager();
      manager.addDartCreatedInstance(new Marker(), 7);
      let threw: boolean = false;
      let message: string = '';
      try {
        manager.addDartCreatedInstance(new Marker(), 7);
      } catch (err) {
        threw = true;
        message = `${err}`;
      }
      expect(threw).assertTrue();
      expect(message.includes('Identifier has already been added')).assertTrue();
    })

    it('removeDropsInstance', 0, () => {
      const manager: InstanceManager = newManager();
      const instance: Marker = new Marker();
      const id: number = manager.addHostCreatedInstance(instance);
      manager.remove(id);
      // 实际行为：remove() 只清 Instances Map，不清 identifiers WeakMap。
      // 因此按 identifier 查询已失效（真正的"已移除"判据），
      // 而按实例反查仍命中。与 Android 原版（两端同清）存在差异。
      expect(manager.getInstance(id)).assertUndefined();
      expect(manager.containsInstance(instance)).assertTrue();
      expect(manager.getIdentifier(instance)).assertEqual(id);
    })

    it('removeAbsentIdentifierDoesNotThrow', 0, () => {
      const manager: InstanceManager = newManager();
      let threw: boolean = false;
      try {
        manager.remove(99999);
      } catch (err) {
        threw = true;
      }
      expect(threw).assertFalse();
    })

    it('clearRemovesAllInstances', 0, () => {
      const manager: InstanceManager = newManager();
      const a: Marker = new Marker();
      const b: Marker = new Marker();
      manager.addHostCreatedInstance(a);
      manager.addDartCreatedInstance(b, 42);
      manager.clear();
      expect(manager.containsInstance(a)).assertFalse();
      expect(manager.containsInstance(b)).assertFalse();
      expect(manager.getInstance(42)).assertUndefined();
    })

    it('addAfterClearWorks', 0, () => {
      const manager: InstanceManager = newManager();
      manager.addHostCreatedInstance(new Marker());
      manager.clear();
      const fresh: Marker = new Marker();
      const id: number = manager.addHostCreatedInstance(fresh);
      // 实际行为：clear() 清空两个容器但不重置 nextIdentifier 计数器，
      // 分配继续自增。与 Android 原版（重置为起点）存在差异。
      expect(id).assertEqual(65537);
      expect(manager.containsInstance(fresh)).assertTrue();
    })

    it('stopFinalizationListenerSetsFlag', 0, () => {
      const manager: InstanceManager = newManager();
      expect(manager.fHasFinalizationListenerStopped()).assertFalse();
      manager.stopFinalizationListener();
      expect(manager.fHasFinalizationListenerStopped()).assertTrue();
    })

    it('reachesThousandInstanceWarningThreshold', 0, () => {
      const manager: InstanceManager = newManager();
      let lastId: number = -1;
      for (let i = 0; i < 1000; i++) {
        lastId = manager.addHostCreatedInstance(new Marker());
      }
      // 第 1000 个实例触发 Log.w 警告分支，但注册流程不受影响。
      expect(lastId).assertEqual(65536 + 999);
      expect(manager.getIdentifier(manager.getInstance(lastId))).assertEqual(lastId);
    })
  })
}
