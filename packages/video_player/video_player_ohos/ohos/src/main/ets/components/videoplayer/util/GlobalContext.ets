export class GlobalContext {
  private constructor() {
  }

  private static instance: GlobalContext;
  private _objects = new Map<string, Object>();

  public static getContext(): GlobalContext {
    if (!GlobalContext.instance) {
      GlobalContext.instance = new GlobalContext();
    }
    return GlobalContext.instance;
  }

  getObject(value: string): Object | undefined {
    return this._objects.get(value);
  }

  /**
   * 移除单个缓存对象（如单播放器 dispose 后不再需要的 windowClass 引用）。
   */
  removeObject(key: string): void {
    this._objects.delete(key);
  }

  setObject(key: string, objectClass: Object): void {
    this._objects.set(key, objectClass);
  }

  /**
   * 清理全部缓存对象，避免静态单例长期持有 window/videoList 等引用导致泄漏。
   * 在播放器批量释放（initialize/detach）时调用。
   */
  clear(): void {
    this._objects.clear();
  }
}
