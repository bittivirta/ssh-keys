#!/bin/bash

# Color Variables
Color_Off='\033[0m'       # Text Reset

Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

bBlack='\033[1;30m'       # Bold Black
bRed='\033[1;31m'         # Bold Red
bGreen='\033[1;32m'       # Bold Green
bYellow='\033[1;33m'      # Bold Yellow
bBlue='\033[1;34m'        # Bold Blue
bPurple='\033[1;35m'      # Bold Purple
bCyan='\033[1;36m'        # Bold Cyan
bWhite='\033[1;37m'       # Bold White

# Get the users.json file
USERS=$(curl -s https://raw.githubusercontent.com/bittivirta/ssh-keys/main/users.json)

function welcome() {
    echo -e "${bBlue}Welcome to the Bittivirta Staff Key importer!${Color_Off}\n"
}

function checkDepedencies() {
    # Check if jq is installed
    if ! command -v jq &> /dev/null
    then
        echo -e "${bRed}Error: ${Red}jq is not installed!${Color_Off}"
        echo -e "${blue}Would you like to install it? (y/n)${Color_Off}"
        read install
        if [ "$install" == "y" ]; then
            sudo apt update && sudo apt install jq || echo -e "${bRed}Error: ${Red}Failed to install jq!${Color_Off}"
        else
            echo -e "${bRed}The jq package is required to run this script. Aborting...${Color_Off}"
            exit 1
        fi
    fi
}

function listUsers() {
    echo -e "${bBlue}Available users:${Color_Off}\n"
    echo "$USERS" | jq -r '.[] | "\(.id). \(.username), \(.name)"' | tr -d '”'
}

function askUserID() {
    echo -e "\n"
    echo -ne "${Blue}Enter the user ID to import:${Color_Off} "
    read -r key
    KEY=$key
}

function getUserKeyByID() {
    echo $key
    # Check if the key exists
    USERNAME=$(echo "$USERS" | jq -r ".[] | select(.id == $KEY) | .username")


    if [ "$USERNAME" != "" ]; then
        return 0
    fi

    # Get the key
    SSHKEYURL=$(echo "$USERS" | jq -r ".[] | select(.id == $KEY) | .keys")
    SSHKEY=$(curl -s "$SSHKEYURL")
}

function getUserKeyByUsername() {
    # Check if the key exists
    USERNAME=$(echo "$USERS" | jq -r ".[] | select(.username == \"$KEY\") | .username")

    if [ "$USERNAME" != "" ]; then
        return 0
    fi

    # Get the key
    SSHKEYURL=$(echo "$USERS" | jq -r ".[] | select(.username == \"$KEY\") | .keys")
    SSHKEY=$(curl -s "$SSHKEYURL")
}

function getUserKey() {
    getUserKeyByID
    if [ $? -eq 0 ]; then
        getUserKeyByUsername
    fi
    if [ $? -eq 0 ]; then
        echo -e "${bRed}Error: ${Red}User not found by ID or username!${Color_Off}"
        exit 1
    fi
}

function askConfirmation() {
    echo -e "${Blue}The key will be imported to the current user's authorized_keys file (~/.ssh/authorized_keys).${Color_Off}\n"
    echo -ne "${bBlue}Continue? (y/n)${Color_Off} "
    read confirm

    if [ "$confirm" != "y" ]; then
        echo -e "${bRed}Aborting...${Color_Off}"    §
        exit 1
    fi
}

function importKey() {
    # Import the key
    echo -e "${bBlue}Importing the key...${Color_Off}"

    grep -qxF "$SSHKEY" ~/.ssh/authorized_keys || echo "$SSHKEY" >> ~/.ssh/authorized_keys && SUCCESS=1
    grep -qxF "$SSHKEY" ~/.ssh/authorized_keys || SUCCSS=0

    # Check if the key was imported
    if [ "$SUCCESS" != 1 ]; then
        echo -e "${bRed}Error: ${Red}Failed to import the key!${Color_Off}"
        exit 1
    fi

    # Success message
    echo -e "${bGreen}Key imported successfully!${Color_Off}"
}

function warnRemoval() {
    echo -e "\n${bRed}Warning: ${Red}Please remember to remove the key from the file when it is no longer needed!"
    echo -e "         ${Red}If the key is not removed and the key is compromised, the attacker can access the server!"
}

function main() {
    welcome
    checkDepedencies
    listUsers
    askUserID
    getUserKey
    askConfirmation
    importKey
    warnRemoval
}
main