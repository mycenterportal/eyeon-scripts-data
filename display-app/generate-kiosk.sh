#!/bin/bash

# Define the input file
input_file="values.txt"

# Function to read input from user with default value
read_input() {
  local prompt=$1
  local default=$2
  local varname=$3
  read -p "$prompt [$default]: " input
  eval $varname="${input:-$default}"
}

# Load previous values if they exist
if [ -f "$input_file" ]; then
  source "$input_file"
  read_input "First URL" "$url1" url1
  read_input "Second URL" "$url2" url2
  read_input "Screen width" "$primary_width" primary_width
else
  read -p "First URL: " url1
  read -p "Second URL: " url2
  read -p "Screen width: " primary_width
fi

# Save the inputs to the file
cat <<EOL > $input_file
url1="$url1"
url2="$url2"
primary_width="$primary_width"
EOL

# Automatically determine the home directory
homedir=$(eval echo ~$USER)

# Create the output file
output_file="kiosk.sh"

# Write the content to the output file
cat <<EOL > $output_file
#!/bin/bash

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
primary_width=$primary_width # Primary or left monitor width in pixels
monitor1="--window-position=0,0"
monitor2="--window-position=\${primary_width},0"

# Home directory of the current user
homedir="$homedir"

# Chrome user data directories
chrome1="\${homedir}/ChromeData/1"
chrome2="\${homedir}/ChromeData/2"

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

