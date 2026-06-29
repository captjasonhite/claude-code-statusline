#!/usr/bin/env python3
import json, sys, subprocess, os, time, datetime

data = json.load(sys.stdin)

model = data['model']['display_name']
proj  = data['workspace']['project_dir']
now   = time.time()

cw = data.get('context_window', {})
rl = data.get('rate_limits', {})

ctx_raw      = cw.get('used_percentage')
ctx_pct      = float(ctx_raw) if ctx_raw is not None else 0.0

five_h_usage = rl.get('five_hour', {}).get('used_percentage')
five_h_reset = rl.get('five_hour', {}).get('resets_at')
week_usage   = rl.get('seven_day',  {}).get('used_percentage')
week_reset   = rl.get('seven_day',  {}).get('resets_at')

def elapsed_pct(resets_at, window_secs):
    if resets_at is None:
        return None
    elapsed = now - (resets_at - window_secs)
    return max(0.0, min(100.0, elapsed / window_secs * 100))

five_h_time_pct = elapsed_pct(five_h_reset, 5 * 3600)
week_time_pct   = elapsed_pct(week_reset,   7 * 24 * 3600)

CYAN     = '\033[36m'
DIM      = '\033[2m'
RESET    = '\033[0m'
FG_BLACK = '\033[30m'
FG_DIM   = '\033[2;37m'
BG_GREEN  = '\033[42m'
BG_YELLOW = '\033[43m'
BG_RED    = '\033[41m'
BG_DARK   = '\033[100m'

def bg_color(pct):
    if pct >= 90: return BG_RED
    if pct >= 70: return BG_YELLOW
    return BG_GREEN

def make_bg_bar(pct, text):
    n     = len(text)
    split = round(pct / 100 * n)
    filled = f"{bg_color(pct)}{FG_BLACK}{text[:split]}{RESET}"
    empty  = f"{BG_DARK}{FG_DIM}{text[split:]}{RESET}" if split < n else ''
    return filled + empty

BAR_WIDTH = 12

def metric_str(label, pct, label_width=15):
    if pct is None:
        return None
    lbl = (label + ':').ljust(label_width)
    return f"{DIM}{lbl}{RESET}{make_bg_bar(pct, ' ' * BAR_WIDTH)} {pct:3.0f}%"

def time_metric_str(label, pct, reset_str, label_width=15):
    if pct is None:
        return None
    lbl = (label + ':').ljust(label_width)
    return f"{DIM}{lbl}{RESET}{make_bg_bar(pct, reset_str.ljust(BAR_WIDTH))} {pct:3.0f}%"

def paired_line(left_label, left_pct, right_label, right_pct, label_width=15):
    left  = metric_str(left_label,  left_pct,  label_width)
    right = metric_str(right_label, right_pct, label_width)
    if left and right:
        return left + '  ' + right
    return left or right

# Git branch (run from project dir, skip optional lock)
branch = ''
try:
    b = subprocess.check_output(
        ['git', '-C', proj, '-c', 'gc.auto=0', 'branch', '--show-current'],
        stderr=subprocess.DEVNULL, text=True
    ).strip()
    if b:
        branch = f" {DIM}on{RESET} {CYAN}{b}{RESET}"
except Exception:
    pass

proj_name = os.path.basename(proj)

ctx_str = metric_str("Context", ctx_pct) or ''
print(f"{CYAN}[{model}]{RESET} {DIM}{proj_name}{RESET}{branch}  {ctx_str}")

def fmt_reset(ts, include_day=False):
    if ts is None:
        return ''
    dt = datetime.datetime.fromtimestamp(ts)
    t  = dt.strftime('%I:%M%p').lstrip('0').lower()
    return f"{dt.strftime('%a').lower()} {t}" if include_day else t

session_reset = fmt_reset(five_h_reset)
weekly_reset  = fmt_reset(week_reset, include_day=True)

row1 = paired_line("Session Usage", five_h_usage, "Weekly Usage", week_usage)
left2  = time_metric_str("Session Time", five_h_time_pct, session_reset) if session_reset else metric_str("Session Time", five_h_time_pct)
right2 = time_metric_str("Weekly Time",  week_time_pct,  weekly_reset)  if weekly_reset  else metric_str("Weekly Time",  week_time_pct)
row2 = (left2 + '  ' + right2) if left2 and right2 else (left2 or right2)

if row1: print(row1)
if row2: print(row2)
