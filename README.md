# claude-code-statusline

A custom status line for [Claude Code](https://claude.ai/code) that shows context usage, session and weekly token usage, and reset times — all as color-coded background-fill bars. It lines things up so you can see where you're at. Why burn tokens when I already did it for you.

![Status line showing Context, Session Usage, Weekly Usage, Session Time, and Weekly Time bars](claude-code-statusline-screenshot.png)

```
[Claude Sonnet 4.6] myproject on main    Context:          25%
Session Usage:               40%    Weekly Usage:     18%
Session Time:  11:42pm       62%    Weekly Time:  tue 3:00pm  44%
```

Bars are green below 70%, yellow from 70–89%, red at 90%+.

## Requirements

- Python 3
- Claude Code
- Session/Weekly bars require a paid Claude.ai subscription and only appear after the first API response in a session

## Installation

1. Copy `statusline.sh` to `~/.claude/`:

   ```bash
   cp statusline.sh ~/.claude/statusline.sh
   chmod +x ~/.claude/statusline.sh
   ```

2. Add to `~/.claude/settings.json`:

   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "~/.claude/statusline.sh"
     }
   }
   ```

3. Restart Claude Code.

## Notes

- Context bar is always visible; Session and Weekly bars are subscriber-only and appear after the first API call each session.
- Reset times are shown in your local timezone inside the Session Time and Weekly Time bars.
- Tested on Linux and macOS.
