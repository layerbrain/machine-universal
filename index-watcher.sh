#!/bin/bash
# index-watcher.sh — Maintains ~/.index.txt (one filepath per line) using inotify
BRAIN_DIR="$HOME/brain"
INDEX="$HOME/.index.txt"

# Initial full scan
find "$BRAIN_DIR" -type f \
  -not -path "*/node_modules/*" \
  -not -path "*/.git/*" \
  -not -path "*/__pycache__/*" \
  -not -path "*/.venv/*" \
  > "$INDEX"

echo "[index-watcher] Initial scan complete: $(wc -l < "$INDEX") files indexed"

# Watch for changes and update index.txt
inotifywait -mrq -e create,delete,moved_to,moved_from --format '%e %w%f' "$BRAIN_DIR" \
  --exclude '(node_modules|\.git|__pycache__|\.venv)' | while read event path; do
  case "$event" in
    CREATE|MOVED_TO)
      # Only add files (not directories)
      [ -f "$path" ] && echo "$path" >> "$INDEX"
      ;;
    DELETE|MOVED_FROM)
      # Remove path from index (sed in-place)
      sed -i "\|^${path}$|d" "$INDEX"
      ;;
  esac
done
