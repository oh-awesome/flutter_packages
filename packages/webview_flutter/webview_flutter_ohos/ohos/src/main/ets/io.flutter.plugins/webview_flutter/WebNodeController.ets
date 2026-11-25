// Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.

import { BuilderNode, FrameNode, NodeController, NodeRenderType, UIContext } from '@kit.ArkUI';
import { Params } from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';
import { WebBuilder } from './OhosWebView';
import { WebViewPlatformView } from './WebViewHostApiImpl';
import Log from '@ohos/flutter_ohos/src/main/ets/util/Log';
import FlutterManager from '@ohos/flutter_ohos/src/main/ets/embedding/ohos/FlutterManager';
import { FlutterView } from '@ohos/flutter_ohos/src/main/ets/view/FlutterView';

const TAG: string = 'WebNodeController';

/**
 * Holds the ArkWeb `Web` component of a [WebViewPlatformView] as an
 * "offline" Web component.
 *
 * The Web component is built inside a [BuilderNode] that is owned by this
 * controller instead of the Flutter embedding. It is mounted to the UI
 * through a `NodeContainer` (see `WebContainerBuilder`), which means the
 * component can be detached from and re-attached to the component tree
 * without being destroyed:
 *
 * * When the Flutter widget that displays the WebView is disposed, only the
 *   `NodeContainer` is unmounted. The Web component survives in a detached
 *   state (hidden and inactive, so it does not render or run media) and can
 *   be re-mounted instantly when a new widget reuses the same controller,
 *   keeping the page state and the shared Web render process alive. This
 *   also means the Web component is NOT destroyed when the engine rebuilds
 *   the platform view node (e.g. on system dark/light mode switches), which
 *   keeps the page content and state intact with zero reload.
 *
 * * When the Dart `WebView` instance is finalized (the controller is no
 *   longer used), [release] disposes the `BuilderNode` and frees the memory
 *   (~200MB per Web component) occupied by the Web component.
 *
 * See the HarmonyOS offline Web component guide:
 * https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/web-offline-mode
 */
export class WebNodeController extends NodeController {
  private rootNode: BuilderNode<[Params]> | null = null;

  private webView: WebViewPlatformView;

  private released: boolean = false;

  // Increments every time a Web component is actually (re)created, i.e. in
  // the lazy creation path of makeNode. WebViewPlatformView uses this to
  // make snapshot-based content restore idempotent per component
  // generation (a re-mount of a live component, e.g. after a color mode
  // switch, keeps the same generation and therefore never triggers a
  // redundant restore).
  private componentGeneration: number = 0;

  // The UIContext and embedding texture surfaceId the live Web component
  // was created with. BuilderNode render bindings are constructor-only:
  // when either changes (e.g. the window's UIContext is recreated after a
  // hide/show cycle, or the engine re-creates the texture), the existing
  // component must be re-created, otherwise it stays logically alive but
  // stops producing frames (blank pixels, a11y/JS still working).
  private creatingUiContext: UIContext | null = null;
  private boundSurfaceId: string = '';

  // Per-view embedding texture surface, transparently provided by the
  // engine through Params.surfaceId (engine fix: EmbeddingNodeController
  // passes the surface it registered for THIS view when building the
  // platform view's builder). Authoritative when set; empty when running
  // on older engines that don't pass it (falls back to the FlutterView
  // lookup in findEmbeddingSurfaceId below).
  private engineSurfaceId: string = '';

  constructor(webView: WebViewPlatformView) {
    super();
    this.webView = webView;
  }

  /**
   * Called by the plugin's platform-view builder (WebContainerBuilder)
   * with the per-view surfaceId received from the embedding via Params.
   * Empty means "not provided by this engine", keep the lookup fallback.
   */
  setEmbeddingSurfaceId(surfaceId: string): void {
    this.engineSurfaceId = surfaceId;
  }

  makeNode(uiContext: UIContext): FrameNode | null {
    if (this.released) {
      return null;
    }
    if (this.rootNode !== null) {
      const currentSurface = this.findEmbeddingSurfaceId();
      const contextChanged = uiContext !== this.creatingUiContext;
      const surfaceChanged = currentSurface !== '' && currentSurface !== this.boundSurfaceId;
      if (contextChanged || surfaceChanged) {
        Log.i(TAG, `makeNode: re-creating Web component, contextChanged=${contextChanged}, ` +
          `surfaceChanged=${surfaceChanged} (${this.boundSurfaceId} -> ${currentSurface})`);
        this.disposeRootNodeOnly();
      } else {
        Log.d(TAG, 'makeNode: re-mounting existing Web component');
        return this.rootNode.getFrameNode();
      }
    }
    // Lazily (re-)create the Web component inside the mounting context.
    Log.d(TAG, 'makeNode: creating Web component');
    this.rootNode = this.createRootNode(uiContext);
    this.creatingUiContext = uiContext;
    this.rootNode.build(new WrappedBuilder(WebBuilder), {
      direction: Direction.Auto,
      platformView: this.webView
    });
    this.componentGeneration += 1;
    return this.rootNode.getFrameNode();
  }

  /**
   * In TLHC (texture hybrid composition) mode the embedding renders the
   * BuilderNode it creates for a platform view on a texture surface
   * (NodeRenderType.RENDER_TYPE_TEXTURE). If the BuilderNode of the offline
   * Web component held by this plugin is not bound to the same render
   * target, its pixels never reach the engine composition and the page
   * shows blank (while the accessibility tree and JS keep working).
   *
   * Prefer the per-view texture surface transparently passed by the engine
   * via Params.surfaceId (available with the engine fix; also accurate when
   * several platform views are on screen). On older engines that don't pass
   * it, fall back to looking up through FlutterManager the surfaceId of the
   * FlutterView that owns this platform view. Known limitation:
   * FlutterView.surfaceId is the texture of the most recently created
   * platform view, so when multiple platform views on the same FlutterView
   * re-mount alternately it may return another view's surface; the thorough
   * fix is the engine-side per-view passthrough above.
   */
  private findEmbeddingSurfaceId(): string {
    // Prefer the per-view surface transparently passed by the engine
    // (Params.surfaceId): it is always THIS view's texture, even when
    // several platform views are on screen and re-mount alternately.
    if (this.engineSurfaceId !== '' && this.engineSurfaceId !== '0') {
      return this.engineSurfaceId;
    }
    try {
      const flutterViews = FlutterManager.getInstance().getFlutterViewList();
      let matched = '';
      let firstWithSurface = '';
      let count = 0;
      flutterViews.forEach((flutterView: FlutterView) => {
        count += 1;
        const id = flutterView.getSurfaceId();
        const valid = id !== undefined && id !== null && id !== '' && id !== '0';
        if (flutterView.getPlatformView() === this.webView && valid) {
          matched = id;
        }
        if (valid && firstWithSurface === '') {
          firstWithSurface = id;
        }
      });
      if (matched !== '') {
        return matched;
      }
      // Fallback: when no FlutterView matches this platformView (e.g. its
      // reference was overwritten by a later view), use the only
      // FlutterView's surfaceId directly if there is just one.
      if (count === 1 && firstWithSurface !== '') {
        return firstWithSurface;
      }
      return '';
    } catch (err) {
      Log.e(TAG, `findEmbeddingSurfaceId err = ${err}`);
      return '';
    }
  }

  private createRootNode(uiContext: UIContext): BuilderNode<[Params]> {
    const surfaceId = this.findEmbeddingSurfaceId();
    this.boundSurfaceId = surfaceId;
    if (surfaceId === '') {
      // No embedding texture surface found (e.g. HCPP display composition
      // mode, or older embeddings): fall back to the default BuilderNode.
      Log.i(TAG, 'createRootNode: no embedding texture surface, fallback to default BuilderNode');
      return new BuilderNode(uiContext);
    }
    Log.i(TAG, `createRootNode: bind to embedding texture surface ${surfaceId}`);
    return new BuilderNode(uiContext, { surfaceId: surfaceId, type: NodeRenderType.RENDER_TYPE_TEXTURE });
  }

  aboutToAppear(): void {
    this.webView.onWebNodeBound();
  }

  aboutToDisappear(): void {
    this.webView.onWebNodeUnbound();
  }

  isReleased(): boolean {
    return this.released;
  }

  getComponentGeneration(): number {
    return this.componentGeneration;
  }

  /**
   * Whether this controller currently holds a live (created and not yet
   * released) Web component.
   */
  hasLiveWebComponent(): boolean {
    return !this.released && this.rootNode !== null;
  }

  /**
   * Fully releases the offline Web component and the memory it occupies.
   *
   * This follows the "release offline Web components" guidance: dispose the
   * `BuilderNode` held by this controller and refresh the bound
   * `NodeContainer` (if any) so the released node is unmounted.
   */
  release(): void {
    if (this.released) {
      return;
    }
    this.released = true;
    this.disposeRootNode();
  }

  /**
   * Disposes the current BuilderNode WITHOUT touching the terminal
   * `released` state, so that a new component can be lazily re-created by
   * the next `makeNode`.
   */
  private disposeRootNodeOnly(): void {
    try {
      this.rootNode?.dispose();
    } catch (err) {
      Log.e(TAG, `disposeRootNodeOnly err = ${err}`);
    }
    this.rootNode = null;
  }

  private disposeRootNode(): void {
    this.disposeRootNodeOnly();
    try {
      this.rebuild();
    } catch (err) {
      Log.e(TAG, `rebuild err = ${err}`);
    }
  }
}
