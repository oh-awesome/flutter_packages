/*
* Copyright 2013 The Flutter Authors
* Use of this source code is governed by a BSD-style license that can be
* found in the LICENSE file.
*/
import StandardMessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMessageCodec';
import BasicMessageChannel, { Reply } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BasicMessageChannel';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import MessageCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/MessageCodec';
import { ByteBuffer } from '@ohos/flutter_ohos/src/main/ets/util/ByteBuffer';


export const aStringConstant: string = "stringConstantValue";
export const anIntConstant: number = 42;
export const aDoubleConstant: number = 3.14;
export const aBoolConstant: boolean = true;

function pigeonDoubleEquals(a: number, b: number): boolean {
  return (a === 0 ? 0 : a) === (b === 0 ? 0 : b) || (isNaN(a) && isNaN(b));
}

function pigeonFloatEquals(a: number, b: number): boolean {
  const af: number = Math.fround(a === 0 ? 0 : a);
  const bf: number = Math.fround(b === 0 ? 0 : b);
  return af === bf || (isNaN(af) && isNaN(bf));
}

function pigeonDoubleHashCode(value: number): number {
  const normalized: number = value === 0 ? 0 : value;
  const buffer: ArrayBuffer = new ArrayBuffer(8);
  const floatView: Float64Array = new Float64Array(buffer);
  const intView: Int32Array = new Int32Array(buffer);
  floatView[0] = normalized;
  return intView[0] ^ intView[1];
}

function pigeonFloatHashCode(value: number): number {
  const normalized: number = Math.fround(value === 0 ? 0 : value);
  const buffer: ArrayBuffer = new ArrayBuffer(4);
  const floatView: Float32Array = new Float32Array(buffer);
  const intView: Int32Array = new Int32Array(buffer);
  floatView[0] = normalized;
  return intView[0];
}

interface PigeonEquals {
  equals(other: ESObject): boolean;
}

interface PigeonHashable {
  hashCode(): number;
}

function pigeonDeepEquals(a: ESObject | null | undefined, b: ESObject | null | undefined): boolean {
  if (a === b) {
    return true;
  }
  if (a == null || b == null) {
    return false;
  }
  if (Array.isArray(a) && Array.isArray(b)) {
    const listA: ESObject[] = a as ESObject[];
    const listB: ESObject[] = b as ESObject[];
    if (listA.length !== listB.length) {
      return false;
    }
    for (let i = 0; i < listA.length; i++) {
      if (!pigeonDeepEquals(listA[i], listB[i])) {
        return false;
      }
    }
    return true;
  }
  if (a instanceof Map && b instanceof Map) {
    const mapA: Map<ESObject, ESObject> = a as Map<ESObject, ESObject>;
    const mapB: Map<ESObject, ESObject> = b as Map<ESObject, ESObject>;
    if (mapA.size !== mapB.size) {
      return false;
    }
    const mapAKeys: ESObject[] = Array.from(mapA.keys());
    for (let i = 0; i < mapAKeys.length; i++) {
      const mapKey: ESObject = mapAKeys[i];
      const mapValue: ESObject | undefined = mapA.get(mapKey);
      let found: boolean = false;
      const mapBKeys: ESObject[] = Array.from(mapB.keys());
      for (let j = 0; j < mapBKeys.length; j++) {
        const bKey: ESObject = mapBKeys[j];
        if (pigeonDeepEquals(mapKey, bKey)) {
          const bValue: ESObject | undefined = mapB.get(bKey);
          if (pigeonDeepEquals(mapValue, bValue)) {
            found = true;
            break;
          } else {
            return false;
          }
        }
      }
      if (!found) {
        return false;
      }
    }
    return true;
  }
  if (typeof a === 'number' && typeof b === 'number') {
    return pigeonDoubleEquals(a as number, b as number);
  }
  if (typeof a === 'object' && typeof b === 'object') {
    const aObj: ESObject = a as ESObject;
    if (typeof (aObj as PigeonEquals).equals === 'function') {
      return (aObj as PigeonEquals).equals(b as ESObject);
    }
  }
  if (typeof a !== typeof b) {
    return false;
  }
  return a === b;
}

function pigeonDeepHashCode(value: ESObject | null | undefined): number {
  if (value == null) {
    return 0;
  }
  if (Array.isArray(value)) {
    let result: number = 1;
    const list: ESObject[] = value as ESObject[];
    for (let i = 0; i < list.length; i++) {
      result = 31 * result + pigeonDeepHashCode(list[i]);
    }
    return result;
  }
  if (value instanceof Map) {
    let result: number = 0;
    const map: Map<ESObject, ESObject> = value as Map<ESObject, ESObject>;
    const mapKeys: ESObject[] = Array.from(map.keys());
    for (let i = 0; i < mapKeys.length; i++) {
      const mapKey: ESObject = mapKeys[i];
      const mapValue: ESObject | undefined = map.get(mapKey);
      result += ((pigeonDeepHashCode(mapKey) * 31) ^ pigeonDeepHashCode(mapValue));
    }
    return result;
  }
  if (typeof value === 'number') {
    return pigeonDoubleHashCode(value as number);
  }
  if (typeof value === 'string') {
    let result: number = 0;
    const str: string = value as string;
    for (let i = 0; i < str.length; i++) {
      result = 31 * result + str.charCodeAt(i);
    }
    return result;
  }
  if (typeof value === 'boolean') {
    return (value as boolean) ? 1231 : 1237;
  }
  if (typeof value === 'object') {
    const valueObj: ESObject = value as ESObject;
    if (typeof (valueObj as PigeonHashable).hashCode === 'function') {
      return (valueObj as PigeonHashable).hashCode();
    }
  }
  return 0;
}


/** Error class for passing custom error details to Flutter via a thrown PlatformException. */
export class FlutterError implements Error {

  /** The error code. */
  public code: string;

  /** The error message. */
  public message: string;

  /** The error details. Must be a datatype supported by the api codec. */
  public details: Object | null;

  /** Error name for the Error interface. */
  public name: string = 'FlutterError';
  /** The error stack. */
  public stack?: string;

  constructor(code: string, message: string, details: Object | null, stack?: string) {
    this.code = code;
    this.message = message;
    this.details = details;
    this.stack = stack;
  }
}

/**
 * Wrapper so PigeonCodec always serializes a Dart `double` as float64.
 * ArkTS `number` values such as `1` or `1.0` would otherwise be encoded
 * as integers by StandardMessageCodec and fail strict Dart double casts.
 */
export class PigeonInternalDoubleBox {
  value: number;
  constructor(value: number) {
    this.value = value;
  }
}

function createConnectionError(channelName: string): FlutterError {
  return new FlutterError('channel-error', 'Unable to establish connection on channel: \'' + channelName + '\'.', '');
}

function createNullReplyError(): FlutterError {
  return new FlutterError('null-error', 'Flutter api returned null value for non-null return value.', '');
}

function wrapError(error: Error): Array<Object | null> {
  let errorList: Array<Object | null> = new Array<Object | null>(3);
  if (error instanceof FlutterError) {
    let err: FlutterError = error as FlutterError;
    errorList[0] = err.code;
    errorList[1] = err.message;
    errorList[2] = err.details;
  } else {
    errorList[0] = error.name;
    errorList[1] = error.toString();
    errorList[2] = "Cause: " + error.message + ", Stacktrace: " + error.stack;
  }
  return errorList;
}
/**
 * Maintains a 1:1 mapping between native objects and integer identifiers
 * shared with the Dart `InstanceManager`.
 *
 * Memory management mirrors Kotlin/Swift: each instance is tracked with a
 * [WeakRef] and a strong reference. [remove] drops the strong reference; when
 * the weak reference is garbage collected, [FinalizationRegistry] notifies the
 * [finalizationListener]. [getIdentifierForStrongReference] re-creates a strong
 * reference when needed to pass an identifier to Dart.
 *
 * Thread safety: synchronous, single-threaded platform channel thread (see
 * Kotlin `InstanceManager` rationale).
 */
export class PigeonInstanceManager {
  private static readonly minHostCreatedIdentifier: number = 65536;

  private readonly weakInstances: Map<number, WeakRef<ESObject>> = new Map<number, WeakRef<ESObject>>();
  private readonly strongInstances: Map<number, ESObject> = new Map<number, ESObject>();
  private finalizationRegistry: FinalizationRegistry<number> | null;
  private readonly instancesHeldForFinalization: Set<ESObject> = new Set<ESObject>();
  private nextIdentifier: number = PigeonInstanceManager.minHostCreatedIdentifier;
  private finalizationListener: PigeonFinalizationListener | null = null;
  private finalizationListenerStopped: boolean = false;

  constructor() {
    const manager: PigeonInstanceManager = this;
    this.finalizationRegistry = new FinalizationRegistry<number>((identifier: number) => {
      if (manager.finalizationListenerStopped) {
        return;
      }
      if (manager.strongInstances.has(identifier)) {
        return;
      }
      manager.weakInstances.delete(identifier);
      if (manager.finalizationListener !== null) {
        manager.finalizationListener.onFinalize(identifier);
      }
    });
  }

  setFinalizationListener(listener: PigeonFinalizationListener | null): void {
    this.finalizationListener = listener;
  }

  stopFinalizationListener(): void {
    this.finalizationListenerStopped = true;
    this.finalizationListener = null;
    if (this.finalizationRegistry !== null) {
      this.instancesHeldForFinalization.forEach((instance: ESObject) => {
        this.finalizationRegistry!.unregister(instance);
      });
      this.finalizationRegistry = null;
    }
    this.instancesHeldForFinalization.clear();
  }

  hasFinalizationListenerStopped(): boolean {
    return this.finalizationListenerStopped;
  }

  private findIdentifierForInstance(instance: ESObject): number | null {
    let found: number | null = null;
    this.strongInstances.forEach((strong: ESObject, identifier: number) => {
      if (found === null && strong === instance) {
        found = identifier;
      }
    });
    if (found !== null) {
      return found;
    }
    this.weakInstances.forEach((weakRef: WeakRef<ESObject>, identifier: number) => {
      if (found !== null) {
        return;
      }
      const deref: ESObject | undefined = weakRef.deref();
      if (deref !== undefined && deref === instance) {
        found = identifier;
      }
    });
    return found;
  }

  private addInstance(instance: ESObject, identifier: number): void {
    if (identifier < 0) {
      throw new Error('Identifier must be >= 0: ' + identifier);
    }
    if (this.weakInstances.has(identifier)) {
      throw new Error('Identifier has already been added: ' + identifier);
    }
    const weakRef: WeakRef<ESObject> = new WeakRef(instance);
    this.weakInstances.set(identifier, weakRef);
    this.strongInstances.set(identifier, instance);
    if (this.finalizationRegistry !== null) {
      this.finalizationRegistry.register(instance, identifier, instance);
      this.instancesHeldForFinalization.add(instance);
    }
  }

  addDartCreatedInstance(instance: ESObject, identifier: number): void {
    this.addInstance(instance, identifier);
  }

  addHostCreatedInstance(instance: ESObject): number {
    if (this.findIdentifierForInstance(instance) !== null) {
      throw new Error('Instance has already been added.');
    }
    const identifier: number = this.nextIdentifier++;
    this.addInstance(instance, identifier);
    return identifier;
  }

  getInstance(identifier: number): ESObject | null {
    const strong: ESObject | undefined = this.strongInstances.get(identifier);
    if (strong !== undefined) {
      return strong;
    }
    const weak: WeakRef<ESObject> | undefined = this.weakInstances.get(identifier);
    if (weak === undefined) {
      return null;
    }
    const deref: ESObject | undefined = weak.deref();
    return deref === undefined ? null : deref;
  }

  getIdentifierForStrongReference(instance: ESObject | null): number | null {
    if (instance === null || instance === undefined) {
      return null;
    }
    const identifier: number | null = this.findIdentifierForInstance(instance);
    if (identifier !== null) {
      this.strongInstances.set(identifier, instance);
    }
    return identifier;
  }

  containsInstance(instance: ESObject | null): boolean {
    if (instance === null || instance === undefined) {
      return false;
    }
    return this.findIdentifierForInstance(instance) !== null;
  }

  remove(identifier: number): ESObject | null {
    const instance: ESObject | undefined = this.strongInstances.get(identifier);
    if (instance === undefined) {
      return null;
    }
    this.strongInstances.delete(identifier);
    this.instancesHeldForFinalization.delete(instance);
    if (this.finalizationRegistry !== null) {
      this.finalizationRegistry.unregister(instance);
    }
    return instance;
  }

  clear(): void {
    if (this.finalizationRegistry !== null) {
      this.instancesHeldForFinalization.forEach((instance: ESObject) => {
        this.finalizationRegistry!.unregister(instance);
      });
    }
    this.instancesHeldForFinalization.clear();
    this.weakInstances.clear();
    this.strongInstances.clear();
  }

  getDebugInfo(): string {
    const idParts: string[] = [];
    this.weakInstances.forEach((_weakRef: WeakRef<ESObject>, identifier: number) => {
      idParts.push(identifier.toString());
    });
    const registeredIdentifiers: string = idParts.join(', ');
    return 'PigeonInstanceManager state: instanceCount='
      + this.weakInstances.size
      + ', strongCount=' + this.strongInstances.size
      + ', nextIdentifier=' + this.nextIdentifier
      + ', registeredIdentifiers=[' + registeredIdentifiers + ']';
  }
}

export interface PigeonFinalizationListener {
  onFinalize(identifier: number): void;
}


/**
 * Generated API for managing the Dart and native `PigeonInstanceManager`s.
 *
 * Set up by `PigeonProxyApiRegistrar` in setUp() / tearDown().
 */
export class PigeonInstanceManagerApi {
  binaryMessenger: BinaryMessenger;

  constructor(binaryMessenger: BinaryMessenger) {
    this.binaryMessenger = binaryMessenger;
  }

  /** The shared codec used by `PigeonInstanceManagerApi`. */
  static getCodec(): MessageCodec<Object> {
    return PigeonCodec.INSTANCE;
  }

  /** Registers (or removes) message handlers that let Dart drive this manager. */
  static setUpMessageHandlers(
    binaryMessenger: BinaryMessenger,
    instanceManager: PigeonInstanceManager | null,
  ): void {
    // removeStrongReference
    {
      let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
        binaryMessenger,
        "dev.flutter.pigeon.pigeon_example_app.PigeonInternalInstanceManager.removeStrongReference",
        PigeonInstanceManagerApi.getCodec());
      if (instanceManager != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>): void {
            if (!(Array.isArray(message))) {
              reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
              return;
            }
            let args: Array<Object> = message as Array<Object>;
            if (args.length < 1) {
              reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
              return;
            }
            let identifierArg: number = args[0] as number;
            if (typeof identifierArg !== 'number') {
              reply.reply(wrapError(new Error('Invalid Pigeon message: identifier must be a number.')));
              return;
            }
            let res: Array<Object | null> = [];
            try {
              instanceManager!.remove(identifierArg);
              res.push(null);
            } catch (error) {
              res = wrapError(error as Error);
            }
            reply.reply(res);
          }
        });
      } else {
        channel.setMessageHandler(null);
      }
    }
    // clear
    {
      let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
        binaryMessenger,
        "dev.flutter.pigeon.pigeon_example_app.PigeonInternalInstanceManager.clear",
        PigeonInstanceManagerApi.getCodec());
      if (instanceManager != null) {
        channel.setMessageHandler({
          onMessage(message: Object, reply: Reply<Object>): void {
            let res: Array<Object | null> = [];
            try {
              instanceManager!.clear();
              res.push(null);
            } catch (error) {
              res = wrapError(error as Error);
            }
            reply.reply(res);
          }
        });
      } else {
        channel.setMessageHandler(null);
      }
    }
  }

  /**
   * Asks the Dart-side InstanceManager to release the strong reference for
   * the identifier so that the Dart proxy object can be garbage collected.
   */
  removeStrongReference(identifierArg: number, callback: Reply<void>): void {
    const channelName: string = 'dev.flutter.pigeon.pigeon_example_app.PigeonInternalInstanceManager.removeStrongReference';
    let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      this.binaryMessenger, channelName, PigeonInstanceManagerApi.getCodec());
    channel.send([identifierArg], channelReply => {
      // Errors on the Dart side are intentionally swallowed; the worst case
      // is a Dart-side memory leak that the developer can debug if needed.
      callback.reply();
    });
  }
}


/**
 * No-op [Reply] for fire-and-forget InstanceManager callbacks.
 * ArkTS rejects untyped object literals for interface-typed parameters
 * (arkts-no-untyped-obj-literals).
 */
class PigeonNoOpVoidReply implements Reply<void> {
  reply(_value: void): void {
  }
}

class PigeonRegistrarFinalizationListener implements PigeonFinalizationListener {
  private readonly api: PigeonInstanceManagerApi;

  constructor(api: PigeonInstanceManagerApi) {
    this.api = api;
  }

  onFinalize(identifier: number): void {
    this.api.removeStrongReference(identifier, new PigeonNoOpVoidReply());
  }
}

/**
 * Provides implementations for each ProxyApi class and shared resources.
 *
 * Subclass this in the host plugin, override each `getXxx()` to return your
 * implementation of `PigeonApi<ApiName>`, then call setUp() from
 * onAttachedToEngine and tearDown() from onDetachedFromEngine.
 */
export abstract class PigeonProxyApiRegistrar {
  public binaryMessenger: BinaryMessenger;
  public instanceManager: PigeonInstanceManager;
  /** Whether ProxyApi calls into Dart should be suppressed (e.g. during shutdown). */
  public ignoreCallsToDart: boolean = false;
  private codecInstance: MessageCodec<Object> | null = null;

  constructor(binaryMessenger: BinaryMessenger) {
    this.binaryMessenger = binaryMessenger;
    this.instanceManager = new PigeonInstanceManager();
    const api: PigeonInstanceManagerApi = new PigeonInstanceManagerApi(binaryMessenger);
    this.instanceManager.setFinalizationListener(new PigeonRegistrarFinalizationListener(api));
  }

  /** Returns the shared `PigeonProxyApiBaseCodec`, lazily instantiated. */
  getCodec(): MessageCodec<Object> {
    if (this.codecInstance === null) {
      this.codecInstance = new PigeonProxyApiBaseCodec(this);
    }
    return this.codecInstance!;
  }

  /** An implementation of [PigeonApiHostEnumCounter] used to register a new Dart instance of `HostEnumCounter` with the Dart `InstanceManager`. */
  abstract getHostEnumCounter(): PigeonApiHostEnumCounter;

  /** An implementation of [PigeonApiEnumCounter] used to register a new Dart instance of `EnumCounter` with the Dart `InstanceManager`. */
  abstract getEnumCounter(): PigeonApiEnumCounter;

  /** Registers all message handlers and InstanceManager handlers. */
  setUp(): void {
    PigeonInstanceManagerApi.setUpMessageHandlers(this.binaryMessenger, this.instanceManager);
    PigeonApiHostEnumCounter.setUpMessageHandlers(this.binaryMessenger, this.getHostEnumCounter());
    PigeonApiEnumCounter.setUpMessageHandlers(this.binaryMessenger, this.getEnumCounter());
  }

  /** Tears down all message handlers from the binary messenger. */
  tearDown(): void {
    this.ignoreCallsToDart = true;
    this.instanceManager.stopFinalizationListener();
    this.instanceManager.clear();
    PigeonInstanceManagerApi.setUpMessageHandlers(this.binaryMessenger, null);
    PigeonApiHostEnumCounter.setUpMessageHandlers(this.binaryMessenger, null);
    PigeonApiEnumCounter.setUpMessageHandlers(this.binaryMessenger, null);
  }
}



/* Generated enum from Pigeon that represents data sent in messages.*/
export enum Identity {
  STUDENT,
  TEACHER
}

/* Generated enum Companion class from Pigeon that represents data sent 
   in messages.Do not delete otherwise enum type data transfer will be failed*/
export class IdentityEnum {
  index: string|null = null;
	constructor(index: string){
    this.index = index;
  }
}

/*
*  ProxyApi 真机验证用枚举（与 HostApi 的 [Identity] 区分）。
* 
*  Generated enum from Pigeon that represents data sent in messages.
*/
export enum ProxyRole {
  ADMIN,
  GUEST
}

/*
*  ProxyApi 真机验证用枚举（与 HostApi 的 [Identity] 区分）。
* 
*  Generated enum Companion class from Pigeon that represents data sent 
   in messages.Do not delete otherwise enum type data transfer will be failed
*/
export class ProxyRoleEnum {
  index: string|null = null;
	constructor(index: string){
    this.index = index;
  }
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class Person {
  private name: string;

  public setName(name: string): void {
    this.name = name;
  }

  getName(): string{
    return this.name;
  }

  private age: number;

  public setAge(age: number): void {
    this.age = age;
  }

  getAge(): number{
    return this.age;
  }

  private identity: Identity;

  public setIdentity(identity: Identity): void {
    this.identity = identity;
  }

  getIdentity(): Identity{
    return this.identity;
  }

  constructor(name: string, age: number, identity: Identity) {
    this.name = name;
    this.age = age;
    this.identity = identity;
  }

  toList(): Array<Object | null> {
    let arr: Array<Object | null> = new Array<Object | null>();
    if (this.name === undefined || this.name === null) {
      arr.push(null);
    } else {
      arr.push(this.name);
    }
    if (this.age === undefined || this.age === null) {
      arr.push(null);
    } else {
      arr.push(this.age);
    }
    if (this.identity === undefined || this.identity === null) {
      arr.push(null);
    } else {
      const identityStr = Identity[this.identity as number];
      arr.push(new IdentityEnum(identityStr));
    }
    return arr;
  }

  static fromList(arr: Object[]): Person {
    if (arr == null || arr.length < 3) {
      throw new Error('Invalid Person: expected at least 3 elements.');
    }
    let nameObject: Object = arr[0];
    const name: string = nameObject as string;
    let ageObject: Object = arr[1];
    const age: number = ageObject as number;
    const identityStr: string = arr[2] as string;
    const identity: Identity = Identity[identityStr];
    return new Person(name, age, identity);
  }

  public equals(other: ESObject | null | undefined): boolean {
    if (other == null || !(other instanceof Person)) {
      return false;
    }
    if (this === other) {
      return true;
    }
    let that: Person = other as Person;
    return pigeonDeepEquals(this.name as ESObject, that.name as ESObject) && pigeonDeepEquals(this.age as ESObject, that.age as ESObject) && pigeonDeepEquals(this.identity as ESObject, that.identity as ESObject);
  }

  public hashCode(): number {
    let fields: Array<Object | null> = new Array<Object | null>();
    fields.push('Person');
    fields.push(this.name as Object);
    fields.push(this.age as Object);
    fields.push(this.identity as Object);
    return pigeonDeepHashCode(fields);
  }

  public toString(): string {
    return 'Person(' + 'name=' + this.name + ', ' + 'age=' + this.age + ', ' + 'identity=' + this.identity + ')';
  }
}

/* Generated class from Pigeon that represents data sent in messages.*/
export class Student {
  private name: string;

  public setName(name: string): void {
    this.name = name;
  }

  getName(): string{
    return this.name;
  }

  private age: number;

  public setAge(age: number): void {
    this.age = age;
  }

  getAge(): number{
    return this.age;
  }

  constructor(name: string, age: number) {
    this.name = name;
    this.age = age;
  }

  toList(): Array<Object | null> {
    let arr: Array<Object | null> = new Array<Object | null>();
    if (this.name === undefined || this.name === null) {
      arr.push(null);
    } else {
      arr.push(this.name);
    }
    if (this.age === undefined || this.age === null) {
      arr.push(null);
    } else {
      arr.push(this.age);
    }
    return arr;
  }

  static fromList(arr: Object[]): Student {
    if (arr == null || arr.length < 2) {
      throw new Error('Invalid Student: expected at least 2 elements.');
    }
    let nameObject: Object = arr[0];
    const name: string = nameObject as string;
    let ageObject: Object = arr[1];
    const age: number = ageObject as number;
    return new Student(name, age);
  }

  public equals(other: ESObject | null | undefined): boolean {
    if (other == null || !(other instanceof Student)) {
      return false;
    }
    if (this === other) {
      return true;
    }
    let that: Student = other as Student;
    return pigeonDeepEquals(this.name as ESObject, that.name as ESObject) && pigeonDeepEquals(this.age as ESObject, that.age as ESObject);
  }

  public hashCode(): number {
    let fields: Array<Object | null> = new Array<Object | null>();
    fields.push('Student');
    fields.push(this.name as Object);
    fields.push(this.age as Object);
    return pigeonDeepHashCode(fields);
  }

  public toString(): string {
    return 'Student(' + 'name=' + this.name + ', ' + 'age=' + this.age + ')';
  }
}

export class PigeonCodec extends StandardMessageCodec {
  static readonly INSTANCE: PigeonCodec  = new PigeonCodec();

  getByte(n: number): number {
    let byteArray = new Uint8Array(1);
    byteArray[0] = n;
    return byteArray[0] as number;
  }
  constructor() {
    super();
  }

  readValueOfType(type: number,  buffer: ByteBuffer): ESObject {
    switch (type) {
      case this.getByte(129): {
        let value: Object= super.readValue(buffer);
        return value == null ? null : Identity[value as number];
      }
      case this.getByte(130): {
        let value: Object= super.readValue(buffer);
        return value == null ? null : ProxyRole[value as number];
      }
      case this.getByte(131):
        return Person.fromList(super.readValue(buffer) as Object[]);
      case this.getByte(132):
        return Student.fromList(super.readValue(buffer) as Object[]);
      default:
        return super.readValueOfType(type, buffer);
    }
  }

  writeValue(stream: ByteBuffer , value: ESObject): ESObject{
    if (value instanceof PigeonInternalDoubleBox) {
      stream.writeInt8(this.getByte(6));
      this.writeAlignment(stream, 8);
      stream.writeFloat64((value as PigeonInternalDoubleBox).value, true);
      return;
    } else     if (value instanceof IdentityEnum) {
      stream.writeUint8(this.getByte(129));
      this.writeValue(stream, value == null ? null : Identity[value.index as string]);
    } else if (value instanceof ProxyRoleEnum) {
      stream.writeUint8(this.getByte(130));
      this.writeValue(stream, value == null ? null : ProxyRole[value.index as string]);
    } else if (value instanceof Person) {
      stream.writeUint8(this.getByte(131));
      this.writeValue(stream, (value as Person).toList());
    } else if (value instanceof Student) {
      stream.writeUint8(this.getByte(132));
      this.writeValue(stream, (value as Student).toList());
    } else {
      super.writeValue(stream, value);
    }
  }
}


export interface Result<T> {
  success( result: T ): void;

  error( error: Error): void;
}
/**
 * Codec extending `PigeonCodec` with ProxyApi instance
 * references (tag 128). Host-created
 * instances must be registered via `pigeon_newInstance` before encoding.
 */
export class PigeonProxyApiBaseCodec extends PigeonCodec {
  registrar: PigeonProxyApiRegistrar;

  constructor(registrar: PigeonProxyApiRegistrar) {
    super();
    this.registrar = registrar;
  }

  override readValueOfType(type: number, buffer: ByteBuffer): ESObject {
    if (type === 128) {
      const identifier: number = super.readValue(buffer) as number;
      const instance: ESObject | null = this.registrar.instanceManager.getInstance(identifier);
      if (instance === null) {
        throw new Error('PigeonProxyApiBaseCodec: instance not found for identifier ' + identifier + '. ' + this.registrar.instanceManager.getDebugInfo());
      }
      return instance;
    }
    return super.readValueOfType(type, buffer);
  }

  override writeValue(stream: ByteBuffer, value: ESObject): ESObject {
    if (value === null || typeof value === 'boolean' || typeof value === 'number' || typeof value === 'string' || Array.isArray(value) || value instanceof Map) {
      return super.writeValue(stream, value);
    }

    if (this.registrar.instanceManager.containsInstance(value)) {
      const identifier: number | null = this.registrar.instanceManager.getIdentifierForStrongReference(value);
      if (identifier === null) {
        throw new Error('PigeonProxyApiBaseCodec: no identifier for registered instance. ' + this.registrar.instanceManager.getDebugInfo());
      }
      stream.writeInt8(128);
      return this.writeValue(stream, identifier as Object);
    }

    return super.writeValue(stream, value);
  }
}

/* Generated abstract class from Pigeon that represents a handler of messages from Flutter.*/
export abstract class DemoHostApi {

  abstract sendNull(data: Object | undefined ): Object | undefined;

  abstract sendTrue(data: boolean ): boolean;

  abstract sendFalse(data: boolean ): boolean;

  abstract sendInt(data: number ): number;

  abstract sendDouble(data: number ): number;

  abstract sendString(data: string ): string;

  abstract sendUint8List(data: number[] ): number[];

  abstract sendInt32List(data: number[] ): number[];

  abstract sendInt64List(data: number[] ): number[];

  abstract sendFloat64List(data: number[] ): number[];

  abstract sendList(data: Array<string> ): Array<string>;

  abstract sendMap(data: Map<string, string> ): Map<string, string>;

  abstract sendCustomClass(data: Student ): Student;

  abstract sendNestedDatatype(data: Person ): Person;

  abstract sendEnum(data: Identity ): Identity;

  abstract sendNullableEnum(data: Identity | undefined ): Identity | undefined;

  abstract sendAsyncEnum(data: Identity , result: Result<Identity>): void;

  abstract triggerPlatformEchoEnum(data: Identity , result: Result<Identity>): void;

  abstract triggerPlatformEchoNullableEnum(data: Identity | undefined , result: Result<Identity | undefined>): void;

  abstract flutterInvokeSync(): string;

  abstract flutterInvokeAsync(result: Result<string>): void;

  abstract errorHandling(result: Result<string>): void;

  abstract taskQueueTest(): string;

  abstract triggerPlatformInvokeSync(result: Result<string>): void;

  abstract triggerPlatformInvokeAsync(result: Result<string>): void;
  /*
  *  在宿主侧创建 [HostEnumCounter] 并做枚举 echo（验证 host→Dart pigeon_newInstance、
  *  宿主 echoRole、以及宿主→Flutter flutterEchoNullableRole）
  */
  abstract proxyApiHostCreateAndEcho(result: Result<string>): void;
  /** The codec used by DemoHostApi. */
  static getCodec(): MessageCodec<Object>{
    return PigeonCodec.INSTANCE;
  }
  /*Sets up an instance of `DemoHostApi` to handle messages through the `binaryMessenger`.*/
  static setup(binaryMessenger: BinaryMessenger, api: DemoHostApi | null, messageChannelSuffix: string = ''): void {
    const separatedMessageChannelSuffix: string = messageChannelSuffix !== '' ? '.' + messageChannelSuffix : '';
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendNull' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let output: Object | undefined = api!.sendNull(args[0] as Object | undefined);
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendTrue' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let output: boolean = api!.sendTrue(args[0] as boolean);
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendFalse' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let output: boolean = api!.sendFalse(args[0] as boolean);
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendInt' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let output: number = api!.sendInt(args[0] as number);
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendDouble' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let output: number = api!.sendDouble(args[0] as number);
                res.push(new PigeonInternalDoubleBox(output));
              }
 catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendString' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let output: string = api!.sendString(args[0] as string);
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendUint8List' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let output: number[] = api!.sendUint8List(args[0] as number[]);
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendInt32List' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let output: number[] = api!.sendInt32List(args[0] as number[]);
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendInt64List' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let output: number[] = api!.sendInt64List(args[0] as number[]);
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendFloat64List' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let output: number[] = api!.sendFloat64List(args[0] as number[]);
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendList' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let output: Array<string> = api!.sendList(args[0] as Array<string>);
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendMap' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let output: Map<string, string> = api!.sendMap(args[0] as Map<string, string>);
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendCustomClass' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let output: Student = api!.sendCustomClass(args[0] as Student);
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendNestedDatatype' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let output: Person = api!.sendNestedDatatype(args[0] as Person);
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendEnum' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let pigeonEnumResult: Identity = api!.sendEnum(Identity[args[0] as string]);
                let output: ESObject = pigeonEnumResult === null || pigeonEnumResult === undefined ? null : new IdentityEnum(Identity[pigeonEnumResult as number]);
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendNullableEnum' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let pigeonEnumResult: Identity | undefined = api!.sendNullableEnum((args[0] == null ? null : Identity[args[0] as string]));
                let output: ESObject = pigeonEnumResult === null || pigeonEnumResult === undefined ? null : new IdentityEnum(Identity[pigeonEnumResult as number]);
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.sendAsyncEnum' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              class ResultImp implements Result<Identity>{
                    success(result: Identity): void {
                      let res: Array<Object | null> = [];
                      res.push((result === null || result === undefined ? null : new IdentityEnum(Identity[result as number])));
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<Identity> = new ResultImp();

              try {
                api!.sendAsyncEnum(Identity[args[0] as string], resultCallback);
              }
 catch (error) {
                reply.reply(wrapError(error as Error));
              }
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.triggerPlatformEchoEnum' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              class ResultImp implements Result<Identity>{
                    success(result: Identity): void {
                      let res: Array<Object | null> = [];
                      res.push((result === null || result === undefined ? null : new IdentityEnum(Identity[result as number])));
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<Identity> = new ResultImp();

              try {
                api!.triggerPlatformEchoEnum(Identity[args[0] as string], resultCallback);
              }
 catch (error) {
                reply.reply(wrapError(error as Error));
              }
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.triggerPlatformEchoNullableEnum' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              class ResultImp implements Result<Identity | undefined>{
                    success(result: Identity | undefined): void {
                      let res: Array<Object | null> = [];
                      res.push((result === null || result === undefined ? null : new IdentityEnum(Identity[result as number])));
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<Identity | undefined> = new ResultImp();

              try {
                api!.triggerPlatformEchoNullableEnum((args[0] == null ? null : Identity[args[0] as string]), resultCallback);
              }
 catch (error) {
                reply.reply(wrapError(error as Error));
              }
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.flutterInvokeSync' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let res: Array<Object | null> = [];
              try {
                let output: string = api!.flutterInvokeSync();
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.flutterInvokeAsync' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              class ResultImp implements Result<string>{
                    success(result: string): void {
                      let res: Array<Object | null> = [];
                      res.push(result);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<string> = new ResultImp();

              try {
                api!.flutterInvokeAsync(resultCallback);
              }
 catch (error) {
                reply.reply(wrapError(error as Error));
              }
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.errorHandling' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              class ResultImp implements Result<string>{
                    success(result: string): void {
                      let res: Array<Object | null> = [];
                      res.push(result);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<string> = new ResultImp();

              try {
                api!.errorHandling(resultCallback);
              }
 catch (error) {
                reply.reply(wrapError(error as Error));
              }
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.taskQueueTest' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      // TaskQueue is declared in the IDL but flutter_ohos BasicMessageChannel does not bind a queue; the handler runs on the default platform thread.
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              let res: Array<Object | null> = [];
              try {
                let output: string = api!.taskQueueTest();
                res.push(output);
              }
 catch (error) {
                let wrappedError: Array<Object | null> = wrapError(error);
                res = wrappedError;
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.triggerPlatformInvokeSync' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              class ResultImp implements Result<string>{
                    success(result: string): void {
                      let res: Array<Object | null> = [];
                      res.push(result);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<string> = new ResultImp();

              try {
                api!.triggerPlatformInvokeSync(resultCallback);
              }
 catch (error) {
                reply.reply(wrapError(error as Error));
              }
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.triggerPlatformInvokeAsync' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              class ResultImp implements Result<string>{
                    success(result: string): void {
                      let res: Array<Object | null> = [];
                      res.push(result);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<string> = new ResultImp();

              try {
                api!.triggerPlatformInvokeAsync(resultCallback);
              }
 catch (error) {
                reply.reply(wrapError(error as Error));
              }
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> =
          new BasicMessageChannel(
              binaryMessenger, 'dev.flutter.pigeon.pigeon_example_app.DemoHostApi.proxyApiHostCreateAndEcho' + separatedMessageChannelSuffix, DemoHostApi.getCodec());
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object ,reply: Reply<Object> ) {
              class ResultImp implements Result<string>{
                    success(result: string): void {
                      let res: Array<Object | null> = [];
                      res.push(result);
                      reply.reply(res);
                    }

                    error(error: Error): void {
                      let wrappedError: Array<Object | null> = wrapError(error);
                      reply.reply(wrappedError);
                    }
              }
              let resultCallback: Result<string> = new ResultImp();

              try {
                api!.proxyApiHostCreateAndEcho(resultCallback);
              }
 catch (error) {
                reply.reply(wrapError(error as Error));
              }
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
  }
}
/*
*  宿主创建专用 ProxyApi：无必填 Flutter 回调，Dart 会生成 `pigeon_newInstance` 处理器。
* 
*  Generated host-side adapter for ProxyApi `HostEnumCounter`.
*  Subclass and override the abstract members to provide your
*  HarmonyOS implementation, then return your subclass from the
*  registrar's `getHostEnumCounter()`.
*/
export abstract class PigeonApiHostEnumCounter {
  pigeonRegistrar: PigeonProxyApiRegistrar;

  constructor(pigeonRegistrar: PigeonProxyApiRegistrar) {
    this.pigeonRegistrar = pigeonRegistrar;
  }

  abstract pigeon_defaultConstructor(storedRole: ProxyRole, initial: number, role: ProxyRole): ESObject;

  /* Unattached 枚举字段：宿主 `pigeon_newInstance` 时由宿主 abstract getter 提供。*/
  abstract storedRole(pigeon_instance: ESObject): ProxyRole;

  abstract increment(pigeon_instance: ESObject, by: number): number;

  abstract current(pigeon_instance: ESObject): number;

  abstract echoRole(pigeon_instance: ESObject, value: ProxyRole): ProxyRole;

  abstract echoNullableRole(pigeon_instance: ESObject, value: ProxyRole | undefined): ProxyRole | undefined;

  /** Wires every host-side handler for `HostEnumCounter`. */
  static setUpMessageHandlers(binaryMessenger: BinaryMessenger, api: PigeonApiHostEnumCounter | null): void {
    const codec: MessageCodec<Object> = api != null ? api.pigeonRegistrar.getCodec() : PigeonCodec.INSTANCE;
    {
      let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.HostEnumCounter.pigeon_defaultConstructor", codec);
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 4) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 4 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let pigeon_identifierArg: number = args[0] as number;
                let storedRoleArg: ESObject = ProxyRole[args[1] as string];
                let initialArg: number = args[2] as number;
                let roleArg: ESObject = ProxyRole[args[3] as string];
                api!.pigeonRegistrar.instanceManager.addDartCreatedInstance(api!.pigeon_defaultConstructor(storedRoleArg, initialArg, roleArg), pigeon_identifierArg); res.push(null);
              }
 catch (error) {
                res = wrapError(error as Error);
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.HostEnumCounter.increment", codec);
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let pigeon_instanceArg: /* HostEnumCounter */ ESObject = args[0] as /* HostEnumCounter */ ESObject;
                let byArg: number = args[1] as number;
                let output: ESObject = api!.increment(pigeon_instanceArg, byArg); res.push(output);
              }
 catch (error) {
                res = wrapError(error as Error);
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.HostEnumCounter.current", codec);
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let pigeon_instanceArg: /* HostEnumCounter */ ESObject = args[0] as /* HostEnumCounter */ ESObject;
                let output: ESObject = api!.current(pigeon_instanceArg); res.push(output);
              }
 catch (error) {
                res = wrapError(error as Error);
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.HostEnumCounter.echoRole", codec);
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let pigeon_instanceArg: /* HostEnumCounter */ ESObject = args[0] as /* HostEnumCounter */ ESObject;
                let valueArg: ESObject = ProxyRole[args[1] as string];
                let pigeonEnumResult: ESObject = api!.echoRole(pigeon_instanceArg, valueArg); let output: ESObject = (pigeonEnumResult === null || pigeonEnumResult === undefined ? null : new ProxyRoleEnum(ProxyRole[pigeonEnumResult as number])); res.push(output);
              }
 catch (error) {
                res = wrapError(error as Error);
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.HostEnumCounter.echoNullableRole", codec);
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let pigeon_instanceArg: /* HostEnumCounter */ ESObject = args[0] as /* HostEnumCounter */ ESObject;
                let valueArg: ESObject = (args[1] == null ? null : ProxyRole[args[1] as string]);
                let pigeonEnumResult: ESObject = api!.echoNullableRole(pigeon_instanceArg, valueArg); let output: ESObject = (pigeonEnumResult === null || pigeonEnumResult === undefined ? null : new ProxyRoleEnum(ProxyRole[pigeonEnumResult as number])); res.push(output);
              }
 catch (error) {
                res = wrapError(error as Error);
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
  }

  /**
   * Creates a Dart proxy of [pigeon_instance] and attaches it via the InstanceManager.
   *
   * Any unattached field values are read synchronously from this host adapter via its
   * own field methods (local calls, not channel round-trips) and are sent together with
   * the identifier in a single newInstance message. Exactly one platform channel message
   * is sent regardless of the number of fields.
   */
  pigeon_newInstance(pigeon_instance: ESObject, callback: Reply<void>): void {
    if (this.pigeonRegistrar.ignoreCallsToDart) {
      callback.reply(new FlutterError('ignore-calls-error', 'Calls to Dart are being ignored.', '') as ESObject);
      return;
    }
    if (this.pigeonRegistrar.instanceManager.containsInstance(pigeon_instance)) {
      callback.reply();
      return;
    }
    const pigeon_identifier: number = this.pigeonRegistrar.instanceManager.addHostCreatedInstance(pigeon_instance);
    const storedRoleArg: ESObject = this.storedRole(pigeon_instance);
    const channelName: string = 'dev.flutter.pigeon.pigeon_example_app.HostEnumCounter.pigeon_newInstance';
    let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      this.pigeonRegistrar.binaryMessenger, channelName, this.pigeonRegistrar.getCodec());
    channel.send([pigeon_identifier, (storedRoleArg === null || storedRoleArg === undefined ? null : new ProxyRoleEnum(ProxyRole[storedRoleArg as number]))], channelReply => {
      if (Array.isArray(channelReply)) {
        let listReply: ESObject[] = channelReply as ESObject[];
        if (listReply.length > 1) {
          let arrFirst: string = listReply[0] as string;
          let arrSecond: string = listReply[1] as string;
          let arrThird: string = listReply[2] as string;
          callback.reply(new FlutterError(arrFirst, arrSecond, arrThird) as ESObject);
        } else {
          callback.reply();
        }
      } else {
        callback.reply(createConnectionError(channelName) as ESObject);
      }
    });
  }

  /* 可选 Flutter 回调：宿主反向调用可空枚举路径（见 proxyApiHostCreate / main 全局 handler）。*/
  flutterEchoNullableRole(pigeon_instance: ESObject, valueArg: ProxyRole | undefined, callback: Reply<ProxyRole | undefined>): void {
    if (this.pigeonRegistrar.ignoreCallsToDart) {
      callback.reply(new FlutterError('ignore-calls-error', 'Calls to Dart are being ignored.', '') as ESObject);
      return;
    }
    if (!this.pigeonRegistrar.instanceManager.containsInstance(pigeon_instance)) {
      callback.reply(new FlutterError('missing-instance-error', 'Callback to `HostEnumCounter.flutterEchoNullableRole` failed because native instance was not in the instance manager.', '') as ESObject);
      return;
    }
    const channelName: string = 'dev.flutter.pigeon.pigeon_example_app.HostEnumCounter.flutterEchoNullableRole';
    let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      this.pigeonRegistrar.binaryMessenger, channelName, this.pigeonRegistrar.getCodec());
    channel.send([pigeon_instance, (valueArg === null || valueArg === undefined ? null : new ProxyRoleEnum(ProxyRole[valueArg as number]))], channelReply => {
      if (Array.isArray(channelReply)) {
        let listReply: ESObject[] = channelReply as ESObject[];
        if (listReply.length > 1) {
          let arrFirst: string = listReply[0] as string;
          let arrSecond: string = listReply[1] as string;
          let arrThird: string = listReply[2] as string;
          callback.reply(new FlutterError(arrFirst, arrSecond, arrThird) as ESObject);
        } else {
          callback.reply((listReply[0] == null ? null : ProxyRole[listReply[0] as string]));
        }
      } else {
        callback.reply(createConnectionError(channelName) as ESObject);
      }
    });
  }

}

/*
*  最小 ProxyApi：构造参数含枚举、unattached 枚举字段、宿主方法枚举回显、Flutter 枚举回调。
* 
*  Generated host-side adapter for ProxyApi `EnumCounter`.
*  Subclass and override the abstract members to provide your
*  HarmonyOS implementation, then return your subclass from the
*  registrar's `getEnumCounter()`.
*/
export abstract class PigeonApiEnumCounter {
  pigeonRegistrar: PigeonProxyApiRegistrar;

  constructor(pigeonRegistrar: PigeonProxyApiRegistrar) {
    this.pigeonRegistrar = pigeonRegistrar;
  }

  abstract pigeon_defaultConstructor(storedRole: ProxyRole, initial: number, role: ProxyRole): ESObject;

  abstract increment(pigeon_instance: ESObject, by: number): number;

  abstract current(pigeon_instance: ESObject): number;

  /* 宿主方法：枚举入参/返回（#18 编解码路径）。*/
  abstract echoRole(pigeon_instance: ESObject, value: ProxyRole): ProxyRole;

  abstract echoNullableRole(pigeon_instance: ESObject, value: ProxyRole | undefined): ProxyRole | undefined;

  /** Wires every host-side handler for `EnumCounter`. */
  static setUpMessageHandlers(binaryMessenger: BinaryMessenger, api: PigeonApiEnumCounter | null): void {
    const codec: MessageCodec<Object> = api != null ? api.pigeonRegistrar.getCodec() : PigeonCodec.INSTANCE;
    {
      let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.EnumCounter.pigeon_defaultConstructor", codec);
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 4) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 4 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let pigeon_identifierArg: number = args[0] as number;
                let storedRoleArg: ESObject = ProxyRole[args[1] as string];
                let initialArg: number = args[2] as number;
                let roleArg: ESObject = ProxyRole[args[3] as string];
                api!.pigeonRegistrar.instanceManager.addDartCreatedInstance(api!.pigeon_defaultConstructor(storedRoleArg, initialArg, roleArg), pigeon_identifierArg); res.push(null);
              }
 catch (error) {
                res = wrapError(error as Error);
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.EnumCounter.increment", codec);
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let pigeon_instanceArg: /* EnumCounter */ ESObject = args[0] as /* EnumCounter */ ESObject;
                let byArg: number = args[1] as number;
                let output: ESObject = api!.increment(pigeon_instanceArg, byArg); res.push(output);
              }
 catch (error) {
                res = wrapError(error as Error);
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.EnumCounter.current", codec);
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 1) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 1 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let pigeon_instanceArg: /* EnumCounter */ ESObject = args[0] as /* EnumCounter */ ESObject;
                let output: ESObject = api!.current(pigeon_instanceArg); res.push(output);
              }
 catch (error) {
                res = wrapError(error as Error);
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.EnumCounter.echoRole", codec);
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let pigeon_instanceArg: /* EnumCounter */ ESObject = args[0] as /* EnumCounter */ ESObject;
                let valueArg: ESObject = ProxyRole[args[1] as string];
                let pigeonEnumResult: ESObject = api!.echoRole(pigeon_instanceArg, valueArg); let output: ESObject = (pigeonEnumResult === null || pigeonEnumResult === undefined ? null : new ProxyRoleEnum(ProxyRole[pigeonEnumResult as number])); res.push(output);
              }
 catch (error) {
                res = wrapError(error as Error);
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
    {
      let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(binaryMessenger, "dev.flutter.pigeon.pigeon_example_app.EnumCounter.echoNullableRole", codec);
      if (api != null) {
        channel.setMessageHandler({
            onMessage(message: Object, reply: Reply<Object>) {
              if (!(Array.isArray(message))) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected List.')));
                  return;
              }
              let args: Array<Object> = message as Array<Object>;
              if (args.length < 2) {
                  reply.reply(wrapError(new Error('Invalid Pigeon message: expected at least 2 argument(s).')));
                  return;
              }
              let res: Array<Object | null> = [];
              try {
                let pigeon_instanceArg: /* EnumCounter */ ESObject = args[0] as /* EnumCounter */ ESObject;
                let valueArg: ESObject = (args[1] == null ? null : ProxyRole[args[1] as string]);
                let pigeonEnumResult: ESObject = api!.echoNullableRole(pigeon_instanceArg, valueArg); let output: ESObject = (pigeonEnumResult === null || pigeonEnumResult === undefined ? null : new ProxyRoleEnum(ProxyRole[pigeonEnumResult as number])); res.push(output);
              }
 catch (error) {
                res = wrapError(error as Error);
              }
              reply.reply(res);
            } });
      } else {
        channel.setMessageHandler(null);
      }
    }
  }

  /**
   * Creates a Dart proxy of [pigeon_instance] and attaches it via the InstanceManager.
   *
   * Any unattached field values are read synchronously from this host adapter via its
   * own field methods (local calls, not channel round-trips) and are sent together with
   * the identifier in a single newInstance message. Exactly one platform channel message
   * is sent regardless of the number of fields.
   */
  pigeon_newInstance(pigeon_instance: ESObject, callback: Reply<void>): void {
    if (this.pigeonRegistrar.ignoreCallsToDart) {
      callback.reply(new FlutterError('ignore-calls-error', 'Calls to Dart are being ignored.', '') as ESObject);
      return;
    }
    if (this.pigeonRegistrar.instanceManager.containsInstance(pigeon_instance)) {
      callback.reply();
      return;
    }
    callback.reply(new FlutterError('new-instance-error', 'Attempting to create a new Dart instance of EnumCounter, but the class has a nonnull callback method.', '') as ESObject);
  }

  /* Flutter 回调：宿主反向调用，验证 ProxyApi 的 FlutterApi 枚举路径（非空返回须非 optional 字段）。*/
  flutterEchoRole(pigeon_instance: ESObject, valueArg: ProxyRole, callback: Reply<ProxyRole>): void {
    if (this.pigeonRegistrar.ignoreCallsToDart) {
      callback.reply(new FlutterError('ignore-calls-error', 'Calls to Dart are being ignored.', '') as ESObject);
      return;
    }
    if (!this.pigeonRegistrar.instanceManager.containsInstance(pigeon_instance)) {
      callback.reply(new FlutterError('missing-instance-error', 'Callback to `EnumCounter.flutterEchoRole` failed because native instance was not in the instance manager.', '') as ESObject);
      return;
    }
    const channelName: string = 'dev.flutter.pigeon.pigeon_example_app.EnumCounter.flutterEchoRole';
    let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      this.pigeonRegistrar.binaryMessenger, channelName, this.pigeonRegistrar.getCodec());
    channel.send([pigeon_instance, (valueArg === null || valueArg === undefined ? null : new ProxyRoleEnum(ProxyRole[valueArg as number]))], channelReply => {
      if (Array.isArray(channelReply)) {
        let listReply: ESObject[] = channelReply as ESObject[];
        if (listReply.length > 1) {
          let arrFirst: string = listReply[0] as string;
          let arrSecond: string = listReply[1] as string;
          let arrThird: string = listReply[2] as string;
          callback.reply(new FlutterError(arrFirst, arrSecond, arrThird) as ESObject);
        } else {
    if (listReply[0] == null) {
      callback.reply(createNullReplyError() as ESObject);
    } else {
      callback.reply(ProxyRole[listReply[0] as string]);
    }
        }
      } else {
        callback.reply(createConnectionError(channelName) as ESObject);
      }
    });
  }

  flutterEchoNullableRole(pigeon_instance: ESObject, valueArg: ProxyRole | undefined, callback: Reply<ProxyRole | undefined>): void {
    if (this.pigeonRegistrar.ignoreCallsToDart) {
      callback.reply(new FlutterError('ignore-calls-error', 'Calls to Dart are being ignored.', '') as ESObject);
      return;
    }
    if (!this.pigeonRegistrar.instanceManager.containsInstance(pigeon_instance)) {
      callback.reply(new FlutterError('missing-instance-error', 'Callback to `EnumCounter.flutterEchoNullableRole` failed because native instance was not in the instance manager.', '') as ESObject);
      return;
    }
    const channelName: string = 'dev.flutter.pigeon.pigeon_example_app.EnumCounter.flutterEchoNullableRole';
    let channel: BasicMessageChannel<Object> = new BasicMessageChannel<Object>(
      this.pigeonRegistrar.binaryMessenger, channelName, this.pigeonRegistrar.getCodec());
    channel.send([pigeon_instance, (valueArg === null || valueArg === undefined ? null : new ProxyRoleEnum(ProxyRole[valueArg as number]))], channelReply => {
      if (Array.isArray(channelReply)) {
        let listReply: ESObject[] = channelReply as ESObject[];
        if (listReply.length > 1) {
          let arrFirst: string = listReply[0] as string;
          let arrSecond: string = listReply[1] as string;
          let arrThird: string = listReply[2] as string;
          callback.reply(new FlutterError(arrFirst, arrSecond, arrThird) as ESObject);
        } else {
          callback.reply((listReply[0] == null ? null : ProxyRole[listReply[0] as string]));
        }
      } else {
        callback.reply(createConnectionError(channelName) as ESObject);
      }
    });
  }

}

/* Generated class from Pigeon that represents Flutter messages that can be called from ArkTS.*/
export class DemoFlutterApi {
  binaryMessenger: BinaryMessenger;
  private messageChannelSuffix: string;

  constructor(binaryMessenger: BinaryMessenger, messageChannelSuffix: string = '') {
    this.binaryMessenger = binaryMessenger;
    this.messageChannelSuffix = messageChannelSuffix !== '' ? '.' + messageChannelSuffix : '';
  }

  /** The codec used by DemoFlutterApi. */
  static getCodec(): MessageCodec<Object> {
    return PigeonCodec.INSTANCE;
  }

  platformInvokeSync(callback: Reply<string>):void {
    const channelName: string = 'dev.flutter.pigeon.pigeon_example_app.DemoFlutterApi.platformInvokeSync' + this.messageChannelSuffix;
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, channelName, DemoFlutterApi.getCodec());
    channel.send(
        null,
        channelReply => {
          if (Array.isArray(channelReply)) {
            let listReply: ESObject[] = channelReply as ESObject[] ;
            if (listReply.length > 1) {
              let arrFirst:string = listReply[0] as string;
              let arrSecond:string = listReply[1] as string;
              let arrThird:string = listReply[2] as string;
              let replyArr: ESObject = new FlutterError(arrFirst, arrSecond, arrThird);
              callback.reply(replyArr);
            } else if (listReply[0] == null) {
              let replyNull: ESObject = createNullReplyError();
              callback.reply(replyNull);
            } else {
              let output:string = listReply[0] as string;
              callback.reply(output);
            }
          }  else {
            let connErr: ESObject = createConnectionError(channelName);
            callback.reply(connErr);
          } 
        });
  }
  platformInvokeAsync(callback: Reply<string>):void {
    const channelName: string = 'dev.flutter.pigeon.pigeon_example_app.DemoFlutterApi.platformInvokeAsync' + this.messageChannelSuffix;
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, channelName, DemoFlutterApi.getCodec());
    channel.send(
        null,
        channelReply => {
          if (Array.isArray(channelReply)) {
            let listReply: ESObject[] = channelReply as ESObject[] ;
            if (listReply.length > 1) {
              let arrFirst:string = listReply[0] as string;
              let arrSecond:string = listReply[1] as string;
              let arrThird:string = listReply[2] as string;
              let replyArr: ESObject = new FlutterError(arrFirst, arrSecond, arrThird);
              callback.reply(replyArr);
            } else if (listReply[0] == null) {
              let replyNull: ESObject = createNullReplyError();
              callback.reply(replyNull);
            } else {
              let output:string = listReply[0] as string;
              callback.reply(output);
            }
          }  else {
            let connErr: ESObject = createConnectionError(channelName);
            callback.reply(connErr);
          } 
        });
  }
  platformEchoEnum(valueArg: Identity, callback: Reply<Identity>) {
    const channelName: string = 'dev.flutter.pigeon.pigeon_example_app.DemoFlutterApi.platformEchoEnum' + this.messageChannelSuffix;
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, channelName, DemoFlutterApi.getCodec());
    channel.send(
        [new IdentityEnum(Identity[valueArg as number])],
        channelReply => {
          if (Array.isArray(channelReply)) {
            let listReply: ESObject[] = channelReply as ESObject[] ;
            if (listReply.length > 1) {
              let arrFirst:string = listReply[0] as string;
              let arrSecond:string = listReply[1] as string;
              let arrThird:string = listReply[2] as string;
              let replyArr: ESObject = new FlutterError(arrFirst, arrSecond, arrThird);
              callback.reply(replyArr);
            } else if (listReply[0] == null) {
              let replyNull: ESObject = createNullReplyError();
              callback.reply(replyNull);
            } else {
              let output: ESObject = listReply[0] == null ? null : Identity[listReply[0] as string];
              callback.reply(output);
            }
          }  else {
            let connErr: ESObject = createConnectionError(channelName);
            callback.reply(connErr);
          } 
        });
  }
  platformEchoNullableEnum(valueArg: Identity | undefined, callback: Reply<Identity | undefined>) {
    const channelName: string = 'dev.flutter.pigeon.pigeon_example_app.DemoFlutterApi.platformEchoNullableEnum' + this.messageChannelSuffix;
    let channel: BasicMessageChannel<Object> = 
        new BasicMessageChannel<Object>(
            this.binaryMessenger, channelName, DemoFlutterApi.getCodec());
    channel.send(
        [(valueArg == null ? null : new IdentityEnum(Identity[valueArg as number]))],
        channelReply => {
          if (Array.isArray(channelReply)) {
            let listReply: ESObject[] = channelReply as ESObject[] ;
            if (listReply.length > 1) {
              let arrFirst:string = listReply[0] as string;
              let arrSecond:string = listReply[1] as string;
              let arrThird:string = listReply[2] as string;
              let replyArr: ESObject = new FlutterError(arrFirst, arrSecond, arrThird);
              callback.reply(replyArr);
            } else {
              let output: ESObject = listReply[0] == null ? null : Identity[listReply[0] as string];
              callback.reply(output);
            }
          }  else {
            let connErr: ESObject = createConnectionError(channelName);
            callback.reply(connErr);
          } 
        });
  }
}
