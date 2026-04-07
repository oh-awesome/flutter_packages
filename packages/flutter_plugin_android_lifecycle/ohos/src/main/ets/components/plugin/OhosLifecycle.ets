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
import { AbilityLifecycleCallback } from '@kit.AbilityKit';
import UIAbility from '@ohos.app.ability.UIAbility';
import common from '@ohos.app.ability.common';

export enum LifecycleState {
  INITIAL = 'INITIAL',
  ABILITY_CREATE = 'ABILITY_CREATE',
  ABILITY_FOREGROUND = 'ABILITY_FOREGROUND',
  ABILITY_BACKGROUND = 'ABILITY_BACKGROUND',
  ABILITY_DESTROY = 'ABILITY_DESTROY',
  WINDOW_STAGE_CREATE = 'WINDOW_STAGE_CREATE',
  WINDOW_STAGE_ACTIVE = 'WINDOW_STAGE_ACTIVE',
  WINDOW_STAGE_INACTIVE = 'WINDOW_STAGE_INACTIVE',
  WINDOW_STAGE_DESTROY = 'WINDOW_STAGE_DESTROY'
}

/**
 * 生命周期观察者回调。
 *
 * 注意：该回调会在 ArkTS 主线程中、鸿蒙 AbilityLifecycleCallback 的派发链路上
 * 被同步调用。实现方 **必须** 保持回调快速返回，只做轻量级状态记录或 UI
 * 状态切换，**禁止** 在其中执行耗时操作（如 I/O、复杂计算、网络请求、同步
 * 等待等），以免阻塞主线程、拖慢系统生命周期处理，严重时引发 ANR。
 *
 * 如果确有耗时任务，请在回调内仅记录状态，再通过 setTimeout / Promise /
 * TaskPool 等异步方式在其它线程或下一个事件循环中执行。
 */
export type LifecycleObserver = (state: LifecycleState) => void;

class OhosAbilityLifecycleCallback extends AbilityLifecycleCallback {
  private readonly onStateChange: LifecycleObserver;

  constructor(onStateChange: LifecycleObserver) {
    super();
    this.onStateChange = onStateChange;
  }

  onAbilityCreate(): void {
    this.onStateChange(LifecycleState.ABILITY_CREATE);
  }

  onWindowStageCreate(): void {
    this.onStateChange(LifecycleState.WINDOW_STAGE_CREATE);
  }

  onAbilityForeground(): void {
    this.onStateChange(LifecycleState.ABILITY_FOREGROUND);
  }

  onWindowStageActive(): void {
    this.onStateChange(LifecycleState.WINDOW_STAGE_ACTIVE);
  }

  onWindowStageInactive(): void {
    this.onStateChange(LifecycleState.WINDOW_STAGE_INACTIVE);
  }

  onAbilityBackground(): void {
    this.onStateChange(LifecycleState.ABILITY_BACKGROUND);
  }

  onWindowStageDestroy(): void {
    this.onStateChange(LifecycleState.WINDOW_STAGE_DESTROY);
  }

  onAbilityDestroy(): void {
    this.onStateChange(LifecycleState.ABILITY_DESTROY);
  }
}

export default class OhosLifecycle {
  private static applicationContext: common.ApplicationContext | null = null;
  private static trackerCallbackId: number | null = null;
  private static latestState: LifecycleState = LifecycleState.INITIAL;
  private static readonly instances: Set<WeakRef<OhosLifecycle>> = new Set();

  private currentState: LifecycleState = LifecycleState.INITIAL;
  private readonly observers: Set<LifecycleObserver> = new Set();
  private readonly ability: UIAbility;
  private weakRef: WeakRef<OhosLifecycle>;

  /**
   * 构造 OhosLifecycle 实例。
   *
   * 初始状态假设说明：
   * - OHOS 的 AbilityLifecycleCallback 只能捕获注册之后发生的生命周期事件，
   *   无法回放历史事件；鸿蒙本身也不存在 `INITIAL` 这样的"未开始"状态，
   *   `INITIAL` 仅作为静态 `latestState` 在未收到任何回调前的内部哨兵值。
   * - `FlutterLifecycleAdapter.getAbilityLifecycle` 只会在插件
   *   `onAttachedToAbility` 时被调用，此时对应的 UIAbility 必然已经经过
   *   `onAbilityCreate`；因此当 `latestState === INITIAL` 时，将当前状态
   *   兜底为 `ABILITY_CREATE` 是最小且安全的假设，不会给出比真实生命周期
   *   更靠后的状态。
   * - 如果在本实例创建之前应用已经推进到更靠后的阶段
   *   （例如 ABILITY_FOREGROUND / ABILITY_BACKGROUND）并被 `latestState` 记录，
   *   则直接沿用该真实状态，不再做 `ABILITY_CREATE` 假设。
   * - 若实例在 initializeTracking 之前、或未调用 initializeTracking 的定制场景
   *   下被创建，`ABILITY_CREATE` 可能不代表真实阶段，业务方可在获取实例后
   *   通过 `handleStateChange` 主动校正。
   */
  constructor(ability: UIAbility) {
    this.ability = ability;
    this.currentState = OhosLifecycle.latestState === LifecycleState.INITIAL
      ? LifecycleState.ABILITY_CREATE
      : OhosLifecycle.latestState;
    this.weakRef = new WeakRef(this);
    OhosLifecycle.instances.add(this.weakRef);
  }

  static initializeTracking(applicationContext: common.ApplicationContext): void {
    if (OhosLifecycle.trackerCallbackId != null) {
      return;
    }
    OhosLifecycle.applicationContext = applicationContext;
    OhosLifecycle.trackerCallbackId = applicationContext.on(
      'abilityLifecycle',
      new OhosAbilityLifecycleCallback((state: LifecycleState): void => {
        OhosLifecycle.latestState = state;
        const staleRefs: Array<WeakRef<OhosLifecycle>> = [];
        OhosLifecycle.instances.forEach((weakRef: WeakRef<OhosLifecycle>) => {
          const instance = weakRef.deref();
          if (instance) {
            instance.handleStateChange(state);
          } else {
            staleRefs.push(weakRef);
          }
        });
        staleRefs.forEach((weakRef: WeakRef<OhosLifecycle>) => {
          OhosLifecycle.instances.delete(weakRef);
        });
      })
    );
  }

  static disposeTracking(): void {
    if (OhosLifecycle.applicationContext != null && OhosLifecycle.trackerCallbackId != null) {
      OhosLifecycle.applicationContext.off('abilityLifecycle', OhosLifecycle.trackerCallbackId);
    }
    OhosLifecycle.applicationContext = null;
    OhosLifecycle.trackerCallbackId = null;
    OhosLifecycle.latestState = LifecycleState.INITIAL;
    OhosLifecycle.instances.clear();
  }

  getAbility(): UIAbility {
    return this.ability;
  }

  getCurrentState(): LifecycleState {
    return this.currentState;
  }

  /**
   * Adds an observer and immediately dispatches the current lifecycle state once.
   * Use `addObserverWithoutInitialCall` if only subsequent state changes should be observed.
   */
  addObserver(observer: LifecycleObserver): void {
    this.addObserverInternal(observer, true);
  }

  addObserverWithoutInitialCall(observer: LifecycleObserver): void {
    this.addObserverInternal(observer, false);
  }

  removeObserver(observer: LifecycleObserver): void {
    this.observers.delete(observer);
  }

  dispose(): void {
    OhosLifecycle.instances.delete(this.weakRef);
    this.observers.clear();
  }

  toString(): string {
    return `OhosLifecycle(state=${this.currentState})`;
  }

  private addObserverInternal(observer: LifecycleObserver, dispatchCurrentState: boolean): void {
    this.observers.add(observer);
    if (dispatchCurrentState) {
      observer(this.currentState);
    }
  }

  /**
   * 分发状态变化到所有已注册的 observer。
   *
   * 性能与线程约束：
   * - 该方法运行在 ArkTS 主线程（鸿蒙 AbilityLifecycleCallback 的派发线程）。
   * - observer 回调按 `LifecycleObserver` 文档的约定必须快速返回，禁止在其中
   *   执行耗时操作；此处不会主动把分发切换到异步线程，以保持与上层
   *   (Android Lifecycle) 一致的同步语义和顺序性。
   * - 单个 observer 抛出异常时仅打印告警，不会影响后续 observer 的通知，
   *   降低一个错误 observer 拖累整条生命周期链路的风险。
   */
  handleStateChange(nextState: LifecycleState): void {
    if (this.currentState === nextState) {
      return;
    }
    this.currentState = nextState;
    this.observers.forEach((observer: LifecycleObserver) => {
      try {
        observer(nextState);
      } catch (error) {
        console.error(`OhosLifecycle observer threw on state ${nextState}: ${error}`);
      }
    });
  }
}
