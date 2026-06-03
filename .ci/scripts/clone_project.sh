#!/bin/bash
# Copyright (c) 2025 Huawei Device Co., Ltd. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE_HW file.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# clone project
function clone_project() {
    WORK_DIR=$(pwd)
    PROJECT_DIR="$WORK_DIR/third_party"
    local project_url="$1"
    local target_branchs="$2"
    local target_branch=$(echo $target_branchs | tr ',' '\n' | shuf -n 1)
    local project_name=$(basename "$project_url" .git)

    cd $PROJECT_DIR
    run_cmd "git clone -b $target_branch $project_url"
    cd $project_name
    run_cmd "git branch"
}

clone_project "$@"
