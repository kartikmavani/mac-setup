#!/bin/bash

# 1. Define your preferred apps
APPS=(
    "/Applications/Sublime Text.app"
    "/Applications/Fork.app"
    "/Applications/ExcalidrawZ.app"
    "/Applications/IntelliJ IDEA CE.app"
    "/Applications/Antigravity.app"
    "/Applications/Antigravity.app"
    "/Applications/Rancher Desktop.app"
    "/Applications/Ollama.app"
    "/Applications/Microsoft Outlook.app"
    "/Applications/Google Chrome.app"
    "/Applications/BlueStacks.app"
    "/System/Applications/Music.app"
    "/System/Applications/Calendar.app" 
    "/System/Applications/Notes.app"    
    "/System/Applications/Reminders.app"
    "/System/Applications/Stickies.app"
    "/Applications/WhatsApp.app"
    "/System/Applications/Messages.app"
    "/System/Applications/Journal.app"
    "/System/Applications/Apps.app"
)

PLIST="$HOME/Library/Preferences/com.apple.dock.plist"


echo "Step 1: Setting Visual Preferences (Genie & Autohide)..."
# Set Genie Effect
defaults write com.apple.dock mineffect -string "genie"
# Enable Autohide
defaults write com.apple.dock autohide -bool true

# Size
defaults write com.apple.dock largesize -int 115

#Magnificaiton enabled
defaults write com.apple.dock magnification -bool true

# (Optional) Disable 'Show Recent Apps' for a cleaner look
defaults write com.apple.dock show-recents -bool false
# This wipes only the 'persistent-apps' (icons on the left), leaving folders and Recents.
defaults write com.apple.dock persistent-apps -array ""

echo "Step 2: Injecting new app list..."
for APP_PATH in "${APPS[@]}"; do
    if [ -d "$APP_PATH" ]; then
        echo "Adding $APP_PATH..."
        
        # URL encode the path for Tahoe's file:// scheme
        APP_URL="file://$(python3 -c "import urllib.parse; print(urllib.parse.quote('$APP_PATH'))")/"
        
        # Create the XML tile
        ENTRY="<dict>
            <key>tile-data</key>
            <dict>
                <key>file-data</key>
                <dict>
                    <key>_CFURLString</key><string>$APP_URL</string>
                    <key>_CFURLStringType</key><integer>15</integer>
                </dict>
            </dict>
            <key>tile-type</key><string>file-tile</string>
        </dict>"       
        # Insert at the end of the array (which starts at 0 now)
        plutil -insert persistent-apps.1 -xml "$ENTRY" "$PLIST"
    else
        echo "Skipping: $APP_PATH not found."
    fi
done

echo "Step 3: Flushing cache and restarting Dock..."
# Tahoe requires a 'read' to force the preferences daemon to sync before the kill
defaults read com.apple.dock > /dev/null
killall Dock

echo "Done! Your Dock has been rebuilt."
