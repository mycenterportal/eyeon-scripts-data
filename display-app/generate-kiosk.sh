#!/bin/bash

# Automatically determine the home directory
homeDir=$(eval echo ~$USER)
desktopDir="$homeDir/Desktop"
scriptsDir="$homeDir/eyeon-scripts"

mkdir -p "$scriptsDir"

# Define the input file
variablesFile="$scriptsDir/variables.txt"

# Function to read input from user with default value
read_input() {
  local prompt=$1
  local default=$2
  local varname=$3
  read -p "$prompt [$default]: " input
  eval $varname="${input:-$default}"
}

# Load previous values if they exist
if [ -f "$variablesFile" ]; then
  source "$variablesFile"
  read_input "First URL" "$url1" url1
  read_input "Second URL" "$url2" url2
  read_input "Screen width" "$screen_width" screen_width
else
  read -p "First URL: " url1
  read -p "Second URL: " url2
  read -p "Screen width: " screen_width
fi

# Save the inputs to the file
cat <<EOL > $variablesFile
# Run below command to generate updated kiosk.sh
# wget -O /tmp/eyeon-generate-kiosk.sh https://mycenterportal.github.io/eyeon-scripts-data/display-app/generate-kiosk.sh && sh /tmp/eyeon-generate-kiosk.sh

url1="$url1"
url2="$url2"
screen_width="$screen_width"
EOL

# Create the output file
output_file="$desktopDir/kiosk.sh"

# Write the content to the output file
cat <<EOL > $output_file
#!/bin/bash

log_file="$scriptsDir/logs.txt"
touch "$log_file"

# Function to log messages with timestamps
log_message() {
  local message=$1
  echo "$(date): $message" >> "$log_file"
}

# Function to check internet connectivity
check_internet() {
  wget -q --spider http://google.com
  return $?
}

# Check internet connectivity with retries
attempts=0
max_attempts=3
interval=5

while [ $attempts -lt $max_attempts ]; do
  if check_internet; then
    echo "Internet is connected"
    break
  else
    log_message "Attempt $(($attempts + 1)): No internet connection. Retrying in $interval seconds..."
    attempts=$(($attempts + 1))
    sleep $interval
  fi
done

if [ $attempts -eq $max_attempts ]; then
  log_message "Failed to connect to the internet after $max_attempts attempts."
  echo "No internet connection. Please check your network. See logs.txt for details."
  exit 1
fi

# Your existing script content here...

# Sleep before execution (if necessary)
sleep 8

# App URLs
url1="$url1"
url2="$url2"

# Command Flags
flags="--disable-pinch 
--start-fullscreen 
--disable-infobars 
--disable-session-crashed-bubble 
--disable-features=TranslateUI
--enable-logging
--v=1"

# Windows Positions
screen_width=$screen_width # Primary or left monitor width in pixels
monitor1="--window-position=0,0"
monitor2="--window-position=\${screen_width},0"

# Home directory of the current user
homeDir="$homeDir"

# Chrome user data directories
chrome1="\${homeDir}/ChromeData/1"
chrome2="\${homeDir}/ChromeData/2"

# Create directories if they do not exist
mkdir -p "\$chrome1" "\$chrome2"

# Ensure the DISPLAY environment variable is set
export DISPLAY=:0

# Function to set exit_type to Normal in Preferences
set_exit_type_normal() {
  local chrome_dir=\$1
  local pref_file="\$chrome_dir/Default/Preferences"
  # Check if the Preferences file exists
  if [ -f "\$pref_file" ]; then
    # Modify the exit_type to Normal
    sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' "\$pref_file"
  fi
}

# Modify Preferences file for both user data directories
set_exit_type_normal "\$chrome1"
set_exit_type_normal "\$chrome2"

# Launch Chromium with specified URLs and flags
chromium "\$url1" \$flags \$monitor1 --user-data-dir="\$chrome1" &> /dev/null & disown
sleep 8
chromium "\$url2" \$flags \$monitor2 --user-data-dir="\$chrome2" &> /dev/null & disown
EOL

# Make the output file executable
chmod +x $output_file

echo "$output_file file is generated."

rm -- "$0"