#!/bin/bash

# Color Variables
Reset='\033[0m'       # Text Reset
Red='\033[0;31m'          # Red
Blue='\033[0;34m'         # Blue
Green='\033[0;32m'        # Green
bRed='\033[1;31m'         # Bold Red
bBlue='\033[1;34m'        # Bold Blue
bGreen='\033[1;32m'       # Bold Green

# Get the users.json file
USERS=$(curl -s https://raw.githubusercontent.com/bittivirta/ssh-keys/main/users.json)

function welcome() {
    echo -e "${bBlue}Welcome to the Bittivirta Staff Key importer!\n"
}

function checkDepedencies() {
    # Check if jq is installed
    if ! command -v jq &> /dev/null
    then
        echo -e "${bRed}Error: ${Red}jq is not installed!"
        echo -e "${blue}Would you like to install it? (y/n):${Reset} "
        read install
        if [ "$install" == "y" ]; then
            sudo apt update && sudo apt install jq || echo -e "${bRed}Error: ${Red}Failed to install jq!"
        else
            echo -e "${bRed}The jq package is required to run this script. Aborting..."
            exit 1
        fi
    fi
}

function listUsers() {
    echo -e "${bBlue}Available users:\n"
    echo "$USERS" | jq -r '.[] | "\(.id). \(.username), \(.name)"' | tr -d '”'
}

function askUserID() {
    echo -e "\n"
    echo -ne "${Blue}Enter the user ID to import: ${Reset}"
    read -r key
    KEY=$key
}

function getUserKeyByID() {
    # Check if the key is a number
    if ! [[ "$KEY" =~ ^[0-9]+$ ]]; then
        return 0
    fi

    # Check if the key exists
    USERNAME=$(echo "$USERS" | jq -r ".[] | select(.id == $KEY) | .username")

    if [[ "$USERNAME" == "" ]]; then
        return 0
    fi

    # Get the key
    SSHKEYURL=$(echo "$USERS" | jq -r ".[] | select(.id == $KEY) | .keys")
    SSHKEY="$(curl -s "$SSHKEYURL") bittivirta-staff-key-$USERNAME"
    return 1
}

function getUserKeyByUsername() {
    # Get the key
    USERNAME=$KEY
    SSHKEYURL=$(echo "$USERS" | jq -r ".[] | select(.username == \"$KEY\") | .keys")
    SSHKEY="$(curl -s "$SSHKEYURL") bittivirta-staff-key-$USERNAME"
    return 1
}

function getUserKey() {
    getUserKeyByID
    if [ $? -eq 0 ]; then
        getUserKeyByUsername
        if [ $? -eq 0 ]; then
            echo -e "${bRed}Error: ${Red}User not found by ID or username!"
            exit 1
        fi
    fi
}

function askConfirmation() {
    echo -e "${Blue}The key will be imported to the current user's authorized_keys file (~/.ssh/authorized_keys).\n"
    echo -ne "${bBlue}Continue? (y/n) ${Reset}"
    read confirm

    if [ "$confirm" != "y" ]; then
        echo -e "${bRed}Aborting..."
        exit 1
    fi
}

function importKey() {

    if [ "$USERNAME" == "" ]; then
        return 0
    fi
    
    # Import the key
    echo -e "${Blue}Importing the key for ${Blue}$USERNAME${Blue}..."

    # Check if the file exists
    if [ ! -f ~/.ssh/authorized_keys ]; then
        mkdir -p ~/.ssh
        touch ~/.ssh/authorized_keys
    fi

    # Check if the key already exists
    if [ ! -f ~/.ssh/bittivirta-staff-keys/$USERNAME.pub ]; then
        mkdir -p ~/.ssh/bittivirta-staff-keys
        touch ~/.ssh/bittivirta-staff-keys/$USERNAME.pub
    fi

    KEY=$USERNAME
    getUserKeyByUsername

    # Check if the key was imported
    if [ "$SSHKEY" == " bittivirta-staff-key-$USERNAME" ]; then
        echo -e "${Red}The key for $USERNAME is empty! (not imported)"
        return 0
    fi


    # Add the key to the file
    echo "$SSHKEY" > ~/.ssh/bittivirta-staff-keys/$USERNAME.pub

    # Make sure the key was imported as file
    if ! grep -qxF "$SSHKEY" ~/.ssh/bittivirta-staff-keys/$USERNAME.pub; then
        echo -e "${bRed}Error: ${Red}Failed to import the key for user $USERNAME!"
        exit 1
    fi

    # Add the key to the authorized_keys file
    grep -qxF "$SSHKEY" ~/.ssh/authorized_keys || echo "$SSHKEY" >> ~/.ssh/authorized_keys && SUCCESS=1

    # Make sure the key was imported to the authorized_keys file
    grep -qxF "$SSHKEY" ~/.ssh/authorized_keys || SUCCESS=0
    
    # Check if the key was imported
    if [ "$SUCCESS" != 1 ]; then
        echo -e "${bRed}Error: ${Red}Failed to import the key!"
        exit 1
    fi

    # Success message
    echo -e "${Green}Key for ${bGreen}$USERNAME ${Green}imported successfully!"
}

function importAllKeys() {
    echo "$USERS" | jq -r '.[] | .username' | while read -r USERNAME; do
        SSHKEY=$(echo "$USERS" | jq -r ".[] | select(.username == \"$USERNAME\") | .keys")
        importKey
    done
}

function warnRemoval() {
    echo -e "\n${bRed}Warning: ${Red}Please remember to remove the key from the file when it is no longer needed!"
    echo -e "         ${Red}If the key is not removed and the key is compromised, the attacker can access the server!"
}

function main() {
    welcome
    checkDepedencies
    if [ "$1" == "all" ]; then
        importAllKeys
    else
        listUsers
        askUserID
        getUserKey
        askConfirmation
        importKey
    fi
    warnRemoval
}
main "$@"
echo -e "${Reset}"