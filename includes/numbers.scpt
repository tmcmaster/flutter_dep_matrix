on run argv
    set filePath to item 1 of argv
    tell application "Numbers"
        activate
        set theDoc to open POSIX file filePath
        tell table 1 of sheet 1 of theDoc
            set header row count to 1
            set header column count to 1
        end tell
    end tell
end run
