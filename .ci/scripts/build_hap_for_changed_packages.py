#!/usr/bin/env python3
# Copyright (c) 2025 Huawei Device Co., Ltd. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE_HW file.

import os
import json
import sys
import subprocess
from pathlib import Path
from typing import List, Tuple, Set, Optional
from logger import Logger


def extract_packages_from_pr() -> List[Tuple[str, str]]:
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

    project_root = Path(__file__).parent.parent.parent
    packages: Set[Tuple[str, str]] = set()

    # Define possible ohos example path templates
    path_templates = [
        'packages/{pkg_name}/example/ohos',
        'packages/{pkg_name}/{pkg_name}_ohos/example/ohos',
        'packages/{pkg_name}/example/app/ohos',
    ]

    for file_path in flutter_files:
        parts = file_path.split('/')
        if len(parts) >= 2 and parts[0] == 'packages':
            pkg_name = parts[1]
            ohos_path = find_ohos_example_path(project_root, pkg_name, path_templates)
            if ohos_path:
                packages.add((pkg_name, str(ohos_path)))
            else:
                Logger.warn(f'{pkg_name} has no ohos example')

    return sorted(packages, key=lambda x: x[0])


def find_ohos_example_path(
    project_root: Path,
    pkg_name: str,
    path_templates: List[str]
) -> Optional[Path]:
    """Find the ohos example path for a package"""
    for template in path_templates:
        path = project_root / template.format(pkg_name=pkg_name)
        if path.exists():
            return path
    return None


def build_hap_for_package(package_info: Tuple[str, str], script_dir: Path) -> bool:
    """Build HAP for the specified package"""
    pkg_name, ohos_path = package_info
    Logger.info(f'Building HAP for {pkg_name}...')

    build_hap_script = script_dir / 'build_hap.sh'
    work_dir = script_dir.parent.parent.parent.parent

    relative_path = compute_relative_path(work_dir, ohos_path)

    cmd = ['bash', str(build_hap_script), relative_path, pkg_name]

    try:
        result = subprocess.run(
            cmd,
            cwd=str(work_dir),
            env=os.environ.copy(),
            capture_output=False,
            text=True,
            check=False
        )

        # Flush stdout to ensure logs are captured
        sys.stdout.flush()

        if result.returncode == 0:
            Logger.info(f'✓ {pkg_name} HAP build succeeded')
            return True
        else:
            Logger.error(f'✗ {pkg_name} HAP build failed, exit code: {result.returncode}')
            return False

    except subprocess.CalledProcessError as e:
        Logger.error(f'✗ {pkg_name} HAP build exception: {e}')
        return False
    except Exception as e:
        Logger.error(f'✗ {pkg_name} unknown error: {e}')
        return False


def compute_relative_path(work_dir: Path, ohos_path: str) -> str:
    """Calculate the relative path from third_party

    Args:
        work_dir: Working directory
        ohos_path: Full path to the ohos example

    Returns:
        Relative path (without trailing /ohos)
    """
    third_party_dir = work_dir / 'third_party'
    ohos_path_obj = Path(ohos_path)

    if ohos_path_obj.is_relative_to(third_party_dir):
        relative_path = ohos_path_obj.relative_to(third_party_dir)
        return str(relative_path.parent)  # Remove trailing /ohos, get example directory

    # If path is not as expected, use relative path directly and remove trailing ohos
    return str(ohos_path_obj.parent)


def main() -> int:
    """Main function"""
    packages = extract_packages_from_pr()

    if not packages:
        Logger.warn('No modified packages found')
        return 0

    script_dir = Path(__file__).parent
    Logger.step(f'Starting HAP build for {len(packages)} package(s)')

    success_count = 0
    for pkg in packages:
        if build_hap_for_package(pkg, script_dir):
            success_count += 1

    fail_count = len(packages) - success_count
    Logger.step(f'Build complete: succeeded {success_count}, failed {fail_count}')

    return 0 if fail_count == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
