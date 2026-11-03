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
   * Remove a single cached object (e.g. the windowClass reference no longer needed
   * after a single player's dispose).
   */
  removeObject(key: string): void {
    this._objects.delete(key);
  }

  setObject(key: string, objectClass: Object): void {
    this._objects.set(key, objectClass);
  }

  /**
   * Clear all cached objects to prevent the static singleton from holding references
   * like window/videoList long-term and leaking.
   * Called during batch player release (initialize/detach).
   */
  clear(): void {
    this._objects.clear();
  }
}
