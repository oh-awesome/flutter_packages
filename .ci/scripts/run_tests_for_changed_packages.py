#!/usr/bin/env python3
# Copyright (c) 2025 Huawei Device Co., Ltd. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE_HW file.

import os
import json
import sys
import subprocess
from datetime import datetime
from pathlib import Path
from typing import List, Set
from logger import Logger


PROJECT_ROOT = Path(__file__).parent.parent.parent
TOOL_PATH = PROJECT_ROOT / 'script' / 'tool' / 'bin' / 'flutter_plugin_tools.dart'
WORK_DIR = Path(os.environ.get('WORK_DIR', str(PROJECT_ROOT)))
LOG_DIR = WORK_DIR / 'Archive' / 'out' / 'unit_tests_logs'


def ensure_tool_dependencies() -> bool:
    """Ensure flutter_plugin_tools dependencies are installed"""
    tool_dir = PROJECT_ROOT / 'script' / 'tool'
    tool_pubspec = tool_dir / 'pubspec.yaml'
    if not tool_pubspec.exists():
        Logger.error('Tool pubspec.yaml not found')
        return False
    
    lock_file = tool_dir / 'pubspec.lock'
    if lock_file.exists():
        lock_mtime = lock_file.stat().st_mtime
        pubspec_mtime = tool_pubspec.stat().st_mtime
        if lock_mtime > pubspec_mtime:
            Logger.info('Tool dependencies already installed and up-to-date')
            return True
    
    try:
        result = subprocess.run(
            ['dart', 'pub', 'get'],
            cwd=str(tool_dir),
            capture_output=True,
            text=True,
            check=False
        )
        if result.returncode != 0:
            Logger.error(f'Failed to get tool dependencies: {result.stderr}')
            return False
        Logger.info('Tool dependencies installed')
        return True
    except Exception as e:
        Logger.error(f'Error installing tool dependencies: {e}')
        return False


def extract_packages_from_pr() -> List[str]:
    """Extract modified packages from PR_FILE_PATHS environment variable"""
    pr_file_paths_str = os.environ.get('PR_FILE_PATHS')

    if not pr_file_paths_str:
        Logger.warn('PR_FILE_PATHS environment variable not found')
        return []

    try:
        pr_file_paths = json.loads(pr_file_paths_str)
    except json.JSONDecodeError as e:
        Logger.error(f'JSON parse error: {e}')
        return []

    flutter_files = pr_file_paths.get('flutter_packages', [])
    if not flutter_files:
        Logger.warn('flutter_files is empty')
        return []

    packages: Set[str] = set()

    for file_path in flutter_files:
        parts = file_path.split('/')
        if len(parts) >= 2 and parts[0] == 'packages':
            pkg_name = parts[1]
            packages.add(pkg_name)

    return sorted(packages)


def find_test_directories(pkg_name: str) -> List[str]:
    """Find all test directories for a package and return their relative paths.
    
    Args:
        pkg_name: The package name to search for test directories.
        
    Returns:
        A list of relative paths that have test directories:
        - 'pkg_name' if packages/{pkg_name}/test exists
        - 'pkg_name/pkg_name' if packages/{pkg_name}/{pkg_name}/test exists
        - 'pkg_name/{pkg_name}_ohos' if packages/{pkg_name}/{pkg_name}_ohos/test exists
    """
    pkg_path = PROJECT_ROOT / 'packages' / pkg_name
    results: List[str] = []
    
    for subdir in ('', pkg_name, f'{pkg_name}_ohos'):
        test_path = pkg_path / subdir / 'test' if subdir else pkg_path / 'test'
        if test_path.exists():
            results.append(f'{pkg_name}/{subdir}' if subdir else pkg_name)
    
    return results


def run_tests_for_package(test_path: str, log_file: Path) -> bool:
    """Run dart tests for the specified package
    
    Returns:
        True if tests passed, False otherwise
    """
    Logger.info(f'Running tests for {test_path}...')
    
    try:
        log_f = open(log_file, 'a', encoding='utf-8')
    except IOError as e:
        Logger.error(f'✗ {test_path} failed to open log file: {e}')
        return False
    
    try:
        log_f.write(f'\n{"=" * 80}\n')
        log_f.write(f'Test started at {datetime.now().isoformat()}\n')
        log_f.write(f'Package: {test_path}\n')
        log_f.write(f'Command: dart {TOOL_PATH} dart-test --packages {test_path} --log-timing\n')
        log_f.write('=' * 80 + '\n\n')
        log_f.flush()
        
        result = subprocess.run(
            [
                'dart', str(TOOL_PATH),
                'dart-test',
                '--packages', test_path,
                '--log-timing'
            ],
            cwd=str(PROJECT_ROOT),
            env=os.environ.copy(),
            stdout=log_f,
            stderr=subprocess.STDOUT,
            text=True,
            check=False
        )
        
        if result.returncode == 0:
            Logger.info(f'✓ {test_path} tests passed')
            return True
        else:
            Logger.error(f'✗ {test_path} tests failed, exit code: {result.returncode}')
            return False
    except Exception as e:
        Logger.error(f'✗ {test_path} test error: {e}')
        return False
    finally:
        try:
            log_f.close()
        except Exception:
            pass


def main() -> int:
    """Main function"""
    packages = extract_packages_from_pr()

    if not packages:
        Logger.warn('No modified packages found')
        return 0

    if not ensure_tool_dependencies():
        Logger.error('Failed to ensure tool dependencies')
        return 1

    Logger.step(f'Found {len(packages)} modified package(s): {", ".join(packages)}')
    
    try:
        LOG_DIR.mkdir(parents=True, exist_ok=True)
    except OSError as e:
        Logger.error(f'Failed to create log directory {LOG_DIR}: {e}')
        return 1
    
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    log_file = LOG_DIR / f'unit_tests_{timestamp}.log'
    
    try:
        with open(log_file, 'w', encoding='utf-8') as log_f:
            log_f.write(f'Unit tests started at {datetime.now().isoformat()}\n')
            log_f.write(f'Packages: {", ".join(packages)}\n')
            log_f.write('=' * 80 + '\n')
    except IOError as e:
        Logger.error(f'Failed to write to log file {log_file}: {e}')
        return 1

    success_count = 0
    fail_count = 0
    skipped_count = 0

    for pkg in packages:
        test_directories = find_test_directories(pkg)
        
        if not test_directories:
            Logger.info(f'⊗ {pkg} has no test directory, skipping')
            skipped_count += 1
            continue

        for test_dir in test_directories:
            if run_tests_for_package(test_dir, log_file):
                success_count += 1
            else:
                fail_count += 1

    try:
        with open(log_file, 'a', encoding='utf-8') as log_f:
            log_f.write(f'\n{"=" * 80}\n')
            log_f.write(f'Tests complete at {datetime.now().isoformat()}\n')
            log_f.write(f'Results: passed {success_count}, failed {fail_count}, skipped {skipped_count}\n')
    except IOError as e:
        Logger.error(f'Failed to write final results to log file: {e}')

    Logger.step(f'Tests complete: passed {success_count}, failed {fail_count}, skipped {skipped_count} (log: {log_file})')

    return 0 if fail_count == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
