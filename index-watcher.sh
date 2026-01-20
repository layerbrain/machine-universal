#!/bin/bash
# Index watcher - monitors ~/brain for file changes and updates ~/.index.db
# Uses inotifywait to watch for create, modify, delete, move events

INDEX_DB="$HOME/.index.db"
WATCH_DIR="$HOME/brain"

# Initialize database if needed
init_db() {
    sqlite3 "$INDEX_DB" <<EOF
CREATE TABLE IF NOT EXISTS inodes (
    path TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    kind TEXT DEFAULT 'file',
    type TEXT,
    size INTEGER,
    created TEXT,
    modified TEXT,
    info TEXT,
    hidden INTEGER DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_inodes_kind ON inodes(kind);
CREATE INDEX IF NOT EXISTS idx_inodes_name ON inodes(name);
CREATE INDEX IF NOT EXISTS idx_inodes_modified ON inodes(modified);
EOF
    echo "[index-watcher] Database initialized: $INDEX_DB"
}

# Get file kind based on extension
get_kind() {
    local path="$1"
    local name=$(basename "$path")
    local ext="${name##*.}"

    # Check if directory
    if [ -d "$path" ]; then
        echo "folder"
        return
    fi

    # Determine kind from extension
    case "$ext" in
        py|js|ts|tsx|jsx|go|rs|rb|java|c|cpp|h|hpp|swift|kt|scala)
            echo "Code"
            ;;
        json|yaml|yml|toml|xml|ini|conf|config)
            echo "file"
            ;;
        md|txt|doc|docx|pdf)
            echo "Documents"
            ;;
        jpg|jpeg|png|gif|svg|webp|ico|bmp)
            echo "Images"
            ;;
        mp4|mov|avi|mkv|webm)
            echo "Videos"
            ;;
        mp3|wav|ogg|flac|m4a)
            echo "Music"
            ;;
        *)
            echo "file"
            ;;
    esac
}

# Add or update file in index
index_file() {
    local path="$1"

    # Skip hidden files
    local name=$(basename "$path")
    if [[ "$name" == .* ]]; then
        return
    fi

    # Skip if not exists
    if [ ! -e "$path" ]; then
        return
    fi

    local kind=$(get_kind "$path")
    local size=0
    local modified=""
    local hidden=0

    if [ -f "$path" ]; then
        size=$(stat -c%s "$path" 2>/dev/null || stat -f%z "$path" 2>/dev/null || echo 0)
        modified=$(stat -c%Y "$path" 2>/dev/null || stat -f%m "$path" 2>/dev/null || echo "")
        if [ -n "$modified" ]; then
            modified=$(date -d "@$modified" -Iseconds 2>/dev/null || date -r "$modified" -Iseconds 2>/dev/null || echo "")
        fi
    fi

    # Escape single quotes
    local escaped_path="${path//\'/\'\'}"
    local escaped_name="${name//\'/\'\'}"

    sqlite3 "$INDEX_DB" "INSERT OR REPLACE INTO inodes (path, name, kind, size, modified, hidden) VALUES ('$escaped_path', '$escaped_name', '$kind', $size, '$modified', $hidden);"
}

# Remove file from index
remove_file() {
    local path="$1"
    local escaped_path="${path//\'/\'\'}"
    sqlite3 "$INDEX_DB" "DELETE FROM inodes WHERE path = '$escaped_path';"
}

# Initial scan of existing files
initial_scan() {
    echo "[index-watcher] Scanning existing files in $WATCH_DIR..."
    find "$WATCH_DIR" -type f ! -name '.*' ! -path '*/.*' 2>/dev/null | while read -r file; do
        index_file "$file"
    done
    local count=$(sqlite3 "$INDEX_DB" "SELECT COUNT(*) FROM inodes;")
    echo "[index-watcher] Indexed $count files"
}

# Main
echo "[index-watcher] Starting index watcher for $WATCH_DIR"
init_db
initial_scan

# Watch for changes
echo "[index-watcher] Watching for file changes..."
inotifywait -m -r -e create,modify,delete,move "$WATCH_DIR" 2>/dev/null | while read -r directory events filename; do
    path="${directory}${filename}"

    # Skip hidden files/dirs
    if [[ "$filename" == .* ]] || [[ "$path" == */.* ]]; then
        continue
    fi

    case "$events" in
        CREATE*|MODIFY*|MOVED_TO*)
            index_file "$path"
            echo "[index-watcher] Indexed: $path"
            ;;
        DELETE*|MOVED_FROM*)
            remove_file "$path"
            echo "[index-watcher] Removed: $path"
            ;;
    esac
done
