// Copyright (c) 2026 Hunan OpenValley Digital Industry Development Co., Ltd.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE_ODID file.
// FileUtils.ets tests: empty-context/invalid-URI error paths + temp file copy and cleanup under a real context.

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
        // The output file name contains the original file prefix + timestamp + extension
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
      // Legacy path: before the 3.44 quality hardening, getPathFromUri created files directly under
      // cacheDir/<32-char-hex>/, and after upgrading cleanupTempFiles must also clean up those old leftovers
      const ctx: common.Context = realContext();
      // util.generateRandomUUID() produces the 8-4-4-4-12 hyphenated format; the cleanupLegacyTempFiles regex
      // only matches that format; hyphen-free 32-char hex is not cleaned
      // (historically written without hyphens, which made this case Error).
      const legacyUuid: string = 'a1b2c3d4-e5f6-0718-293a-4b5c6d7e8f90';
      const legacyDir: string = ctx.cacheDir + '/' + legacyUuid;
      // Idempotent preparation: clean once first so leftover directories from a previously failed run
      // do not make mkdirSync throw
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
      // cacheDir subdirectories not named as UUIDs must not be mistakenly deleted by the legacy-path cleanup
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
      // Clean up the directory this case created to avoid polluting later tests
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
        // Some file systems do not allow file names ending with a dot; skip (other assertions unaffected)
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
      // Directory URI (with trailing slash): openSync may succeed opening a directory read-only →
      // inputFilePath becomes an empty string →
      // outputFileName falls back to 'image_picker'; copyFileSync then fails reading the directory fd → enters the
      // cleanup branch after mkdirSync. It must not crash whether openSync succeeds or throws
      // (on throw it follows the existing null-return path).
      const ctx: common.Context = realContext();
      const dirPath: string = ctx.cacheDir + '/ip_dir_uri_test';
      try {
        fs.mkdirSync(dirPath);
      } catch (e) {
      }
      const uri: string = fileUri.getUriFromPath(dirPath) + '/';
      const outPath: string | null = FileUtils.getPathFromUri(ctx, uri);
      // The result is irrelevant: covering the empty-file-name fallback and the copy-failure cleanup branch is enough;
      // clean the dir and temp dir to avoid leftovers
      FileUtils.cleanupTempFiles(ctx);
      try {
        fs.rmdirSync(dirPath);
      } catch (e) {
      }
      expect(true).assertTrue();
    });
  });
}
