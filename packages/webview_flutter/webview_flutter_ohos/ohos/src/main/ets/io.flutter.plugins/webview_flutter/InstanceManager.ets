// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// Based on InstanceManager.java originally written by
// Copyright 2013 The Flutter Authors.

import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import { Queue } from '@kit.ArkTS';

export class InstanceManager {
  private MIN_HOST_CREATED_IDENTIFIER = 65536;

  private CLEAR_FINALIZED_WEAK_REFERENCES_INTERVAL = 3000;

  private TAG = "InstanceManager";

  private finalizationListener: FinalizationListener;

  private identifiers: Map<WeakRef<ESObject>, number> = new Map<WeakRef<ESObject>, number>();
  private weakInstances: Map<number, WeakRef<ESObject>> = new Map<number, WeakRef<ESObject>>();
  private strongInstances: Map<number, ESObject> = new Map<number, ESObject>();
  private referenceQueue: Queue<WeakRef<ESObject>> = new Queue();
  private weakReferencesToIdentifiers: Map<WeakRef<ESObject>, number> = new Map<WeakRef<ESObject>, number>();

  private firstIdentifier: number = 0;

  private nextIdentifier: number = this.MIN_HOST_CREATED_IDENTIFIER;

  private releaseTimer: ESObject = null;

  private hasFinalizationListenerStopped: boolean = false;

  public create<T>(finalizationListener: FinalizationListener): InstanceManager {
    return new InstanceManager(finalizationListener);
  }

  public fHasFinalizationListenerStopped(): boolean {
    return this.hasFinalizationListenerStopped;
  }

  constructor(finalizationListener: FinalizationListener) {
    this.finalizationListener = finalizationListener;
    this.releaseTimer = setTimeout(() => {
      this.releaseAllFinalizedInstances()
    }, this.CLEAR_FINALIZED_WEAK_REFERENCES_INTERVAL)
  }

  public remove(identifier: number): ESObject | null {
    this.logWarningIfFinalizationListenerHasStopped();
    return this.strongInstances.delete(identifier) as ESObject | null;
  }

  getInstance(identifier: number): ESObject | null {
    this.logWarningIfFinalizationListenerHasStopped();
    return this.weakInstances.get(identifier)?.deref();
  }

  clear() {
    this.identifiers.clear();
    this.strongInstances.clear();
    this.weakInstances.clear();
    this.weakReferencesToIdentifiers.clear();
  }

  private releaseAllFinalizedInstances(): void {
    if (this.fHasFinalizationListenerStopped()) {
      return;
    }

    let reference : WeakRef<ESObject> | null = null;
    while ((reference = this.referenceQueue.getFirst()) != null) {
      const identifier: number | undefined = this.weakReferencesToIdentifiers.get(reference);
      this.weakReferencesToIdentifiers.delete(reference);
      if (identifier != undefined) {
        this.weakInstances.delete(identifier);
        this.strongInstances.delete(identifier);
        this.finalizationListener.onFinalize(identifier);
      }
      this.referenceQueue.pop();
    }

    this.releaseTimer = setTimeout(() => {
      this.releaseAllFinalizedInstances()
    }, this.CLEAR_FINALIZED_WEAK_REFERENCES_INTERVAL)
  }

  stopFinalizationListener() {
    if (this.releaseTimer) {
      clearTimeout(this.releaseTimer);
    }
    this.hasFinalizationListenerStopped = true;
  }


  private addInstance(instance: ESObject, identifier: number) {
    if (identifier < 0) {
      throw Error(`Identifier must be >= 0: ${identifier}`);
    }
    if (this.weakInstances.has(identifier)) {
      throw new Error(`Identifier has already been added: ${identifier}`);
    }
    if (this.strongInstances.size === 0) {
      this.firstIdentifier = identifier
    }

    const weakReference: WeakRef<ESObject> = new WeakRef<ESObject>(instance);
    this.referenceQueue.add(weakReference);
    this.identifiers.set(weakReference, identifier); 
    this.weakInstances.set(identifier, weakReference);
    this.weakReferencesToIdentifiers.set(weakReference, identifier);
    this.strongInstances.set(identifier, instance);
  }

  getIdentifier(instance: Object): number {
    this.logWarningIfFinalizationListenerHasStopped();
    return this.identifiers.get(instance as WeakRef<ESObject>) ?? -1;

  }

  private logWarningIfFinalizationListenerHasStopped() {
    if (this.fHasFinalizationListenerStopped()) {
      Log.w(this.TAG, "The manager was used after calls to the FinalizationListener have been stopped.");
    }
  }

  public containsInstance(instance: ESObject): boolean {
    this.logWarningIfFinalizationListenerHasStopped();
    return this.identifiers.has(instance);
  }

  public addHostCreatedInstance(instance: ESObject): number {
    this.logWarningIfFinalizationListenerHasStopped();

    if (this.containsInstance(instance)) {
      throw new Error(
        `Instance of ${instance.constructor.name} has already been added.`);
    }
    const identifier = this.nextIdentifier++;
    this.addInstance(instance, identifier);
    return identifier;
  }

  addDartCreatedInstance(instance: ESObject, identifier: number) {
    this.logWarningIfFinalizationListenerHasStopped();
    this.addInstance(instance, identifier);
  }
}

interface FinalizationListener {
  onFinalize: (identifier: number) => void;
}