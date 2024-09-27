#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 --gameYml <gameYml> --gamePath <gamePath> --lutrisId <lutrisId>"
    exit 1
}

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


# Escape backslashes and spaces in the path
escapedGamePath=$(echo "$gamePath" | sed -e 's/\\/\\\\\\\\/g' -e 's/ /\\\\ /g')

# Run sed to replace the line with the escaped game path
sed -i "s|\(args: \).*|\1$escapedGamePath|" "$gameYml"

/usr/bin/flatpak run net.lutris.Lutris lutris:rungameid/$lutrisId &

sleep 5

while pgrep "lutris" > /dev/null; do
    sleep 1  # Sleep for a second before checking again
done

echo "Application has exited."
Exit 0