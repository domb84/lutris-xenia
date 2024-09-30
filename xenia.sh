#!/bin/bash
logFIle="xenia.log"
# Redirect stdout and stderr to the log file
exec > >(tee -a "$logFIle") 2>&1

# Function to display usage
usage() {
    echo "Usage: $0 --gameYml <gameYml> --gamePath <gamePath> --lutrisId <lutrisId>"
    exit 1
}

xeniaLink="https://github.com/xenia-canary/xenia-canary/releases/download/experimental/xenia_canary.zip"
dateString=$(date +"%d-%m-%Y")
targetDir="xenia-canary" 

# Create the target directory if it doesn't exist
mkdir -p "$targetDir"

# download yq
# Check if the file is readable
if [ -r ./yq ]; then
    echo "yq is installed."
else
    echo "yq is not installed, downloading."
    wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O yq &&\
        chmod +x ./yq
fi

if [ ! -r ./yq ]; then
    echo "yq is still not installed, exiting."
    exit 1
fi

# Check if the correct number of arguments is provided
if [ "$#" -lt 6 ]; then
    usage
fi

# Parse named arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
        --gameYml)
            gameYml="$2"
            shift 2
            ;;
        --gamePath)
            gamePath="$2"
            shift 2
            ;;
        --lutrisId)
            lutrisId="$2"
            shift 2
            ;;
        *)
            echo "Unknown argument: $1"
            usage
            ;;
    esac
done

# Ensure all required arguments are set
if [ -z "$gameYml" ] || [ -z "$gamePath" ] || [ -z "$lutrisId" ]; then
    usage
fi

# Check if the file is readable
if [ -r "$gameYml" ]; then
    echo "The file '$gameYml' is readable."
else
    echo "The file '$gameYml' is not readable or does not exist."
    exit 1
fi

exePath=$(./yq eval '.game.exe' "$gameYml")
exeFileName=$(basename "$exePath")
exeDir=$(dirname "$exePath")

# Check if the exe is readable
if [ -r "$exePath" ]; then
    echo "The exe '$exePath' exists."
else
    echo "The exe '$exePath' does not exist. Exiting."
    exit 1
fi

# Download the file using curl
downloadName=$(basename "$xeniaLink")
wget "$xeniaLink" -O "$downloadName"
# Extract the zip file
unzip -o "$downloadName" -d "$targetDir"

# Use find to locate the file in the directory
downloadExe=$(find "$targetDir" -type f -name "$exeFileName")

# compare the files and replace it if its changed
exeSum=$(md5sum "$exePath" | awk '{ print $1 }')
downloadExeSum=$(md5sum "$downloadExe" | awk '{ print $1 }')

if [ "$exeSum" == "$downloadExeSum" ]; then
    echo "The files are identical. Not updating Xenia."
else
    echo "Xenia has been updated, replacing."
    cp -f "$exePath" "$exeDir/$dateString$exeFileName"
    mv -f "./$downloadExe" "$exePath"
fi

# Escape backslashes and spaces in the path
escapedGamePath=$(echo "$gamePath" | sed -e 's/\\/\\\\\\\\/g' -e 's/ /\\\\ /g')

./yq eval -i ".game.args = \"$escapedGamePath\"" "$gameYml"

/usr/bin/flatpak run net.lutris.Lutris lutris:rungameid/$lutrisId &

sleep 5

while pgrep "lutris" > /dev/null; do
    sleep 1  # Sleep for a second before checking again
done

echo "Application has exited."
exit 0