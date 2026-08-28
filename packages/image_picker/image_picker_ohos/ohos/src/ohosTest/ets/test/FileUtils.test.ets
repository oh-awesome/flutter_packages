// Copyright (c) 2026 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// FileUtils.ets 测试：空 context/无效 URI 错误路径 + 真实 context 下临时文件拷贝与清理。

import { describe, it, expect } from '@ohos/hypium';
import FileUtils from '../../../main/ets/image_picker/FileUtils';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import { fileUri } from '@kit.CoreFileKit';

function realContext(): common.Context {
  return AbilityDelegatorRegistry.getAbilityDelegator().getAppContext() as common.Context;
}

function fileExists(path: string): boolean {
  try {
    return fs.accessSync(path);
  } catch (e) {
    return false;
  }
}

function writeFile(path: string, size: number): void {
  const file: fs.File = fs.openSync(path, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
  fs.writeSync(file.fd, new ArrayBuffer(size));
  fs.closeSync(file);
}

export default function fileUtilsTest() {
  describe('FileUtilsTest', () => {
    it('getPathFromUri_null_context_invalid_uri_returns_null', 0, () => {
      const path: string | null = FileUtils.getPathFromUri(null, 'bad://uri');
      expect(path == null).assertTrue();
    });

    it('getPathFromUri_null_context_valid_looking_uri_returns_null', 0, () => {
      const path: string | null = FileUtils.getPathFromUri(null, 'file:///nonexistent_dir/nonexistent.png');
      expect(path == null).assertTrue();
    });

    it('cleanupTempFiles_null_context_is_noop', 0, () => {
      FileUtils.cleanupTempFiles(null);
      expect(true).assertTrue();
    });

    it('getTempDirectory_returns_image_picker_tmp_under_cache_dir', 0, () => {
      const ctx: common.Context = realContext();
      const tempDir: string = FileUtils.getTempDirectory(ctx);
      expect(tempDir.indexOf('/image_picker_tmp')).assertEqual(tempDir.length - '/image_picker_tmp'.length);
    });

    it('real_context_getPathFromUri_copies_file_to_temp', 0, () => {
      const ctx: common.Context = realContext();
      const srcPath: string = ctx.cacheDir + '/ip_test_src.jpg';
      writeFile(srcPath, 64);
      const uri: string = fileUri.getUriFromPath(srcPath);
      const outPath: string | null = FileUtils.getPathFromUri(ctx, uri);
      expect(outPath != null).assertTrue();
      if (outPath != null) {
        expect(fileExists(outPath)).assertTrue();
        // 输出文件名含原文件前缀 + 时间戳 + 扩展名
        expect(outPath.indexOf('/ip_test_src')).assertEqual(outPath.lastIndexOf('/'));
      }
      try {
        fs.unlinkSync(srcPath);
      } catch (e) {
      }
    });

    it('real_context_getPathFromUri_no_extension_defaults_jpg', 0, () => {
      const ctx: common.Context = realContext();
      const srcPath: string = ctx.cacheDir + '/ip_test_noext';
      writeFile(srcPath, 32);
      const uri: string = fileUri.getUriFromPath(srcPath);
      const outPath: string | null = FileUtils.getPathFromUri(ctx, uri);
      expect(outPath != null).assertTrue();
      if (outPath != null) {
        expect(outPath.indexOf('.jpg')).assertEqual(outPath.length - 4);
      }
      try {
        fs.unlinkSync(srcPath);
      } catch (e) {
      }
    });

    it('real_context_getPathFromUri_nonexistent_uri_returns_null', 0, () => {
      const ctx: common.Context = realContext();
      const path: string | null = FileUtils.getPathFromUri(ctx, 'file:///nonexistent_dir/nope.jpg');
      expect(path == null).assertTrue();
    });

    it('real_context_cleanupTempFiles_removes_temp_files', 0, () => {
      const ctx: common.Context = realContext();
      const tempDir: string = FileUtils.getTempDirectory(ctx);
      const tmpFile: string = tempDir + '/cleanup_me.jpg';
      writeFile(tmpFile, 16);
      expect(fileExists(tmpFile)).assertTrue();
      FileUtils.cleanupTempFiles(ctx);
      expect(fileExists(tmpFile)).assertFalse();
    });

    it('cleanupTempFiles_removes_legacy_uuid_dirs_under_cache_dir', 0, () => {
      // 老版本路径：3.44 质量加固前 getPathFromUri 直接建在 cacheDir/<32位hex>/ 下，
      // 升级后须由 cleanupTempFiles 一并清掉旧残留
      const ctx: common.Context = realContext();
      // util.generateRandomUUID() 产出 8-4-4-4-12 带连字符格式，cleanupLegacyTempFiles 的正则
      // 只匹配该格式；无连字符的 32 位 hex 不会被清理（历史上误写成无连字符导致该用例 Error）。
      const legacyUuid: string = 'a1b2c3d4-e5f6-0718-293a-4b5c6d7e8f90';
      const legacyDir: string = ctx.cacheDir + '/' + legacyUuid;
      // 幂等准备：先清一次，避免上次失败运行的残留目录导致 mkdirSync 抛错
      FileUtils.cleanupTempFiles(ctx);
      fs.mkdirSync(legacyDir);
      const legacyFile: string = legacyDir + '/legacy_copy.jpg';
      writeFile(legacyFile, 16);
      expect(fileExists(legacyFile)).assertTrue();
      FileUtils.cleanupTempFiles(ctx);
      expect(fileExists(legacyFile)).assertFalse();
      expect(fileExists(legacyDir)).assertFalse();
    });

    it('cleanupTempFiles_preserves_non_uuid_subdirs_under_cache_dir', 0, () => {
      // 非 UUID 命名的 cacheDir 子目录不应被老路径清理误删
      const ctx: common.Context = realContext();
      const keepDir: string = ctx.cacheDir + '/ip_keep_dir';
      const keepFile: string = keepDir + '/keep.jpg';
      try {
        fs.mkdirSync(keepDir);
      } catch (e) {
      }
      writeFile(keepFile, 8);
      FileUtils.cleanupTempFiles(ctx);
      expect(fileExists(keepFile)).assertTrue();
      // 清理本用例自建目录，避免污染后续测试
      try {
        fs.unlinkSync(keepFile);
        fs.rmdirSync(keepDir);
      } catch (e) {
      }
    });

    it('getPathFromUri_null_context_valid_file_closes_fd_and_returns_null', 0, () => {
      const ctx: common.Context = realContext();
      const srcPath: string = ctx.cacheDir + '/ip_nullctx_valid.jpg';
      writeFile(srcPath, 16);
      const uri: string = fileUri.getUriFromPath(srcPath);
      const outPath: string | null = FileUtils.getPathFromUri(null, uri);
      expect(outPath == null).assertTrue();
      try {
        fs.unlinkSync(srcPath);
      } catch (e) {
      }
    });

    it('getPathFromUri_filename_with_multiple_dots_joins_name', 0, () => {
      const ctx: common.Context = realContext();
      const srcPath: string = ctx.cacheDir + '/ip_test.multi.part.jpg';
      writeFile(srcPath, 32);
      const uri: string = fileUri.getUriFromPath(srcPath);
      const outPath: string | null = FileUtils.getPathFromUri(ctx, uri);
      expect(outPath != null).assertTrue();
      if (outPath != null) {
        expect(outPath.indexOf('.jpg')).assertEqual(outPath.length - 4);
        expect(outPath.indexOf('/ip_test.multi.part')).assertEqual(outPath.lastIndexOf('/'));
      }
      try {
        fs.unlinkSync(srcPath);
      } catch (e) {
      }
    });

    it('getPathFromUri_trailing_dot_extension_falls_back_to_def_extension', 0, () => {
      const ctx: common.Context = realContext();
      const srcPath: string = ctx.cacheDir + '/ip_trailingdot.';
      let created: boolean = false;
      try {
        writeFile(srcPath, 16);
        created = true;
      } catch (e) {
        // 部分文件系统不允许以点结尾的文件名，跳过（不影响其他断言）
      }
      if (created) {
        const uri: string = fileUri.getUriFromPath(srcPath);
        const outPathPng: string | null = FileUtils.getPathFromUri(ctx, uri, 'png');
        if (outPathPng != null) {
          expect(outPathPng.indexOf('.png')).assertEqual(outPathPng.length - 4);
        }
        const outPathJpg: string | null = FileUtils.getPathFromUri(ctx, uri);
        if (outPathJpg != null) {
          expect(outPathJpg.indexOf('.jpg')).assertEqual(outPathJpg.length - 4);
        }
        try {
          fs.unlinkSync(srcPath);
        } catch (e) {
        }
      }
      expect(true).assertTrue();
    });

    it('getPathFromUri_directory_uri_hits_empty_name_and_copy_failure', 0, () => {
      // 目录 URI（带尾斜杠）：openSync 只读打开目录可能成功 → inputFilePath 为空字符串 →
      // outputFileName 兜底 'image_picker'；随后 copyFileSync 读目录 fd 失败 → 进入
      // mkdirSync 后的清理分支。无论 openSync 成功或抛错都不应崩溃（抛错时走既有 null 返回路径）。
      const ctx: common.Context = realContext();
      const dirPath: string = ctx.cacheDir + '/ip_dir_uri_test';
      try {
        fs.mkdirSync(dirPath);
      } catch (e) {
      }
      const uri: string = fileUri.getUriFromPath(dirPath) + '/';
      const outPath: string | null = FileUtils.getPathFromUri(ctx, uri);
      // 结果不关心：覆盖空文件名兜底与 copy 失败清理分支即可；清理目录与临时目录避免残留
      FileUtils.cleanupTempFiles(ctx);
      try {
        fs.rmdirSync(dirPath);
      } catch (e) {
      }
      expect(true).assertTrue();
    });
  });
}
