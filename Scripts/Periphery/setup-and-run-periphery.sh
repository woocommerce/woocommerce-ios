#!/bin/bash

# Define the Periphery version
PERIPHERY_VERSION="3.2.0"

# Define the path to the periphery executable
REPO_ROOT="$(git rev-parse --show-toplevel)"
PERIPHERY_FOLDER_PATH="${REPO_ROOT}/vendor/Periphery"
PERIPHERY_PATH="${PERIPHERY_FOLDER_PATH}/periphery"

# Function to compare versions
version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

# Function to update and run Periphery
update_periphery() {
    echo "Downloading version $PERIPHERY_VERSION..."
    # Download the zip file
    curl -L "https://github.com/peripheryapp/periphery/releases/download/${PERIPHERY_VERSION}/periphery-${PERIPHERY_VERSION}.zip" -o "periphery.zip"

    # Create target directory if it doesn't exist
    mkdir -p "$PERIPHERY_FOLDER_PATH"

    # Unzip the contents directly into the target directory, overwriting files
    unzip -o periphery.zip -d "$PERIPHERY_FOLDER_PATH"

    # Clean up the zip file
    rm periphery.zip
    
    # Make sure the executable is executable
    chmod +x "$PERIPHERY_PATH"
    
    echo "Download and setup complete."
}

# Check if the executable exists and is executable
if [ -x "$PERIPHERY_PATH" ]; then
    echo "Executable found. Checking version..."
    # Get the current installed version
    CURRENT_VERSION=$("$PERIPHERY_PATH" version)

    # Compare the current version with the desired version
    if version_gt "$PERIPHERY_VERSION" "$CURRENT_VERSION"; then
        echo "Current version ($CURRENT_VERSION) is older than $PERIPHERY_VERSION. Updating..."
        update_periphery
    else
        echo "Current version ($CURRENT_VERSION) is up-to-date."
    fi
else
    echo "Executable not found. Downloading..."
    update_periphery
fi

echo "Running periphery scan..."
# Run periphery scan with additional arguments
"$PERIPHERY_PATH" scan --disable-update-check --relative-results "$@"
