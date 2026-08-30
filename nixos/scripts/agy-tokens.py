#!/usr/bin/env python3
"""
Antigravity Global Token & Quota Reporter
Fetches and displays live global Antigravity token limits, remaining quota,
and reset timers across all model groups (Gemini, Claude, GPT).
"""

import sys
import os
import re
import json
import ssl
import subprocess
import urllib.request
from datetime import datetime, timezone

def format_time_remaining(reset_time_str):
    if not reset_time_str:
        return "Refreshes on next usage"
    try:
        reset_dt = datetime.fromisoformat(reset_time_str.replace("Z", "+00:00"))
        now = datetime.now(timezone.utc)
        diff = reset_dt - now
        total_seconds = int(diff.total_seconds())
        if total_seconds <= 0:
            return "Ready / Reset"
        
        days = total_seconds // 86400
        hours = (total_seconds % 86400) // 3600
        minutes = (total_seconds % 3600) // 60
        
        parts = []
        if days > 0:
            parts.append(f"{days}d")
        if hours > 0 or days > 0:
            parts.append(f"{hours}h")
        parts.append(f"{minutes}m")
        
        return f"Resets in {' '.join(parts)}"
    except Exception:
        return reset_time_str

def make_bar(fraction, width=18):
    pct = max(0.0, min(1.0, fraction))
    filled = int(round(pct * width))
    empty = width - filled
    return "█" * filled + "░" * empty

def get_quota():
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    # Find running language server processes
    try:
        ps = subprocess.check_output(["ps", "-u", os.getenv("USER", "peng"), "-o", "pid,args"], text=True)
    except Exception:
        try:
            ps = subprocess.check_output(["ps", "-A", "-o", "pid,args"], text=True)
        except Exception:
            ps = ""

    ls_info = []
    for line in ps.splitlines():
        if "language_server" in line and "--csrf_token" in line:
            parts = line.strip().split(None, 1)
            try:
                pid = int(parts[0])
            except ValueError:
                continue
            csrf_m = re.search(r"--csrf_token\s+([^\s]+)", line)
            if csrf_m:
                ls_info.append((pid, csrf_m.group(1)))

    if not ls_info:
        return None

    try:
        ss_out = subprocess.check_output(["ss", "-tlpn"], text=True)
    except Exception:
        ss_out = ""

    for pid, csrf in ls_info:
        ports = []
        for line in ss_out.splitlines():
            if f"pid={pid}" in line:
                m = re.search(r"127\.0\.0\.1:(\d+)", line)
                if m:
                    ports.append(int(m.group(1)))
        
        for port in ports:
            url = f"https://127.0.0.1:{port}/exa.language_server_pb.LanguageServerService/RetrieveUserQuotaSummary"
            req = urllib.request.Request(
                url,
                data=b"{}",
                headers={
                    "Content-Type": "application/json",
                    "X-Codeium-Csrf-Token": csrf
                }
            )
            try:
                with urllib.request.urlopen(req, context=ctx, timeout=2) as resp:
                    data = json.loads(resp.read().decode("utf-8"))
                    if "response" in data and "groups" in data["response"]:
                        return data["response"]
            except Exception:
                continue
    return None

def main():
    if "--json" in sys.argv:
        quota = get_quota()
        if quota:
            print(json.dumps(quota, indent=2))
        else:
            print(json.dumps({"error": "Language Server not reachable"}))
        return

    data = get_quota()
    if not data:
        print("Error: Could not retrieve Antigravity quota (Antigravity Language Server is not running).", file=sys.stderr)
        print("Tip: Launch Antigravity IDE or start an `agy` session to initialize the language server.", file=sys.stderr)
        sys.exit(1)

    is_tty = sys.stdout.isatty()
    BOLD = "\033[1m" if is_tty else ""
    CYAN = "\033[36m" if is_tty else ""
    GREEN = "\033[32m" if is_tty else ""
    YELLOW = "\033[33m" if is_tty else ""
    RED = "\033[31m" if is_tty else ""
    RESET = "\033[0m" if is_tty else ""
    DIM = "\033[2m" if is_tty else ""

    def color_pct(pct):
        if not is_tty:
            return f"{pct*100:5.1f}%"
        if pct >= 0.5:
            return f"{GREEN}{pct*100:5.1f}%{RESET}"
        elif pct >= 0.2:
            return f"{YELLOW}{pct*100:5.1f}%{RESET}"
        else:
            return f"{RED}{pct*100:5.1f}%{RESET}"

    print(f"\n{BOLD}⚡ Google Antigravity — Global Token & Quota Status{RESET}\n")

    for group in data.get("groups", []):
        name = group.get("displayName", "Models")
        desc = group.get("description", "")
        print(f"{BOLD}{CYAN}● {name}{RESET} {DIM}({desc}){RESET}")
        
        buckets = group.get("buckets", [])
        order = {"5h": 0, "weekly": 1}
        buckets.sort(key=lambda b: order.get(b.get("window", ""), 2))
        
        for b in buckets:
            d_name = b.get("displayName", b.get("bucketId", "Limit"))
            rem_frac = b.get("remainingFraction", 1.0)
            reset_str = b.get("resetTime")
            timer = format_time_remaining(reset_str)
            bar = make_bar(rem_frac, 18)
            
            bar_color = GREEN if rem_frac >= 0.5 else (YELLOW if rem_frac >= 0.2 else RED)
            if not is_tty:
                bar_color = ""
            
            print(f"  ├─ {d_name:<26}: {bar_color}[{bar}]{RESET} {color_pct(rem_frac)}  {DIM}({timer}){RESET}")
        print()

if __name__ == "__main__":
    main()
