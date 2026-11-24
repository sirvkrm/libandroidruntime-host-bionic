#!/usr/bin/env python3
"""Selective AOSP android-17.0.0_r1 source fetcher (lzhiyong/android-sdk-tools style)."""

from __future__ import annotations

import argparse
import concurrent.futures
import json
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REPOS_JSON = ROOT / "map/repos_needed.json"

# Additional header-only or build-config repos needed beyond Android.bp module edges
EXTRA_REPOS = [
    ("build/soong", "platform/build/soong"),
    ("build/release", "platform/build/release"),
    ("external/gemmlowp", "platform/external/gemmlowp"),
    ("external/google-highway", "platform/external/google-highway"),
    ("external/libjxl", "platform/external/libjxl"),
    ("external/vulkan-headers", "platform/external/vulkan-headers"),
    ("frameworks/av", "platform/frameworks/av"),
    ("hardware/libhardware", "platform/hardware/libhardware"),
    ("system/media", "platform/system/media"),
    ("system/tools/aidl", "platform/system/tools/aidl"),
    ("system/tools/hidl", "platform/system/tools/hidl"),
    ("system/tools/sysprop", "platform/system/tools/sysprop"),
]


def clone_repo(entry: dict, retries: int = 3) -> str:
    dest = ROOT / entry["path"]
    if dest.exists() and (dest / ".git").exists():
        return f"skip {entry['aosp_path']} (exists)"
    cmd = [
        "git", "clone", "-q", "-c", "advice.detachedHead=false",
        "--depth", "1", "--branch", entry["tag"], entry["url"], str(dest),
    ]
    last_err = ""
    for attempt in range(1, retries + 1):
        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode == 0:
            return f"cloned {entry['aosp_path']} ({entry['tag']})"
        last_err = res.stderr.strip()
        shutil.rmtree(dest, ignore_errors=True)
        if attempt < retries:
            time.sleep(3 * attempt)
    raise RuntimeError(f"Failed cloning {entry['url']}: {last_err}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--jobs", type=int, default=6)
    parser.add_argument("--tag", default="android-17.0.0_r1")
    args = parser.parse_args()

    repos = json.loads(REPOS_JSON.read_text(encoding="utf-8"))
    seen = {r["aosp_path"] for r in repos}
    for aosp_path, git_name in EXTRA_REPOS:
        if aosp_path not in seen:
            repos.append({
                "path": f"src/{aosp_path}",
                "aosp_path": aosp_path,
                "url": f"https://android.googlesource.com/{git_name}",
                "tag": args.tag,
            })

    with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as ex:
        for msg in ex.map(clone_repo, repos):
            print(msg)


if __name__ == "__main__":
    main()
