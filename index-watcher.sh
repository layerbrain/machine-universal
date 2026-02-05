#!/bin/bash
# Index watcher - monitors ~/brain for file changes and updates ~/.index.db
# Uses inotifywait to watch for create, modify, delete, move events

INDEX_DB="$HOME/.index.db"
WATCH_DIR="$HOME/brain"
SCAN_ONLY=0

for arg in "$@"; do
    case "$arg" in
        --scan-only|--scan_only)
            SCAN_ONLY=1
            ;;
    esac
done

# Initialize database if needed
init_db() {
    sqlite3 "$INDEX_DB" <<EOF
CREATE TABLE IF NOT EXISTS inodes (
    path TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    parent TEXT,
    kind TEXT DEFAULT 'file',
    type TEXT,
    size INTEGER,
    created TEXT,
    modified TEXT,
    info TEXT,
    hidden INTEGER DEFAULT 0
);
CREATE INDEX IF NOT EXISTS idx_inodes_parent ON inodes(parent);
CREATE INDEX IF NOT EXISTS idx_inodes_kind ON inodes(kind);
CREATE INDEX IF NOT EXISTS idx_inodes_name ON inodes(name);
CREATE INDEX IF NOT EXISTS idx_inodes_modified ON inodes(modified);
EOF
    # Ensure new columns exist for older DBs
    if ! sqlite3 "$INDEX_DB" "PRAGMA table_info(inodes);" | grep -q "|parent|"; then
        sqlite3 "$INDEX_DB" "ALTER TABLE inodes ADD COLUMN parent TEXT;"
    fi
    if ! sqlite3 "$INDEX_DB" "PRAGMA table_info(inodes);" | grep -q "|hidden|"; then
        sqlite3 "$INDEX_DB" "ALTER TABLE inodes ADD COLUMN hidden INTEGER DEFAULT 0;"
    fi
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

    local name=$(basename "$path")

    # Skip if not exists
    if [ ! -e "$path" ]; then
        return
    fi

    local kind=""
    local size=0
    local modified=""
    local hidden=0
    local parent=$(dirname "$path")

    if [[ "$name" == .* ]]; then
        hidden=1
    fi

    if [ -d "$path" ]; then
        kind="folder"
        modified=$(stat -c%Y "$path" 2>/dev/null || stat -f%m "$path" 2>/dev/null || echo "")
    elif [ -f "$path" ]; then
        kind=$(get_kind "$path")
        size=$(stat -c%s "$path" 2>/dev/null || stat -f%z "$path" 2>/dev/null || echo 0)
        modified=$(stat -c%Y "$path" 2>/dev/null || stat -f%m "$path" 2>/dev/null || echo "")
    else
        kind=$(get_kind "$path")
    fi

    # Escape single quotes
    local escaped_path="${path//\'/\'\'}"
    local escaped_name="${name//\'/\'\'}"
    local escaped_parent="${parent//\'/\'\'}"

    sqlite3 "$INDEX_DB" "INSERT OR REPLACE INTO inodes (path, name, parent, kind, size, modified, hidden) VALUES ('$escaped_path', '$escaped_name', '$escaped_parent', '$kind', $size, '$modified', $hidden);"
}

# Remove file from index
remove_file() {
    local path="$1"
    local escaped_path="${path//\'/\'\'}"
    sqlite3 "$INDEX_DB" "DELETE FROM inodes WHERE path = '$escaped_path';"
}

# Remove directory subtree from index
remove_tree() {
    local path="$1"
    local escaped_path="${path//\'/\'\'}"
    sqlite3 "$INDEX_DB" "DELETE FROM inodes WHERE path = '$escaped_path' OR path LIKE '$escaped_path/%';"
}

# Index directory tree (directory + children)
index_tree() {
    local path="$1"
    if [ ! -e "$path" ]; then
        return
    fi
    if [ -d "$path" ]; then
        find "$path" -mindepth 0 -print0 2>/dev/null | while IFS= read -r -d '' entry; do
            index_file "$entry"
        done
    else
        index_file "$path"
    fi
}

# Initial scan of existing files
initial_scan() {
    echo "[index-watcher] Scanning existing files in $WATCH_DIR..."
    find "$WATCH_DIR" -mindepth 1 -print0 2>/dev/null | while IFS= read -r -d '' entry; do
        index_file "$entry"
    done
    local count=$(sqlite3 "$INDEX_DB" "SELECT COUNT(*) FROM inodes;")
    echo "[index-watcher] Indexed $count files"
}

# Main
echo "[index-watcher] Starting index watcher for $WATCH_DIR"
init_db
initial_scan

# Exit after initial scan if requested
if [ "$SCAN_ONLY" -eq 1 ]; then
    echo "[index-watcher] Scan-only mode complete"
    exit 0
fi

# Watch for changes
echo "[index-watcher] Watching for file changes..."
inotifywait -m -r -e create,modify,delete,move --format '%w|%e|%f' "$WATCH_DIR" 2>/dev/null | while IFS='|' read -r directory events filename; do
    path="${directory}${filename}"
    is_dir=0
    if [[ "$events" == *ISDIR* ]]; then
        is_dir=1
    fi

    if [[ "$events" == *CREATE* ]] || [[ "$events" == *MODIFY* ]] || [[ "$events" == *MOVED_TO* ]]; then
        if [ "$is_dir" -eq 1 ]; then
            index_tree "$path"
        else
            index_file "$path"
        fi
        echo "[index-watcher] Indexed: $path"
        continue
    fi

    if [[ "$events" == *DELETE* ]] || [[ "$events" == *MOVED_FROM* ]]; then
        if [ "$is_dir" -eq 1 ]; then
            remove_tree "$path"
        else
            remove_file "$path"
        fi
        echo "[index-watcher] Removed: $path"
        continue
    fi
done
