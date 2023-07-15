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

USERS=$(curl -s https://raw.githubusercontent.com/bittivirta/ssh-keys/main/users.json)

echo -e "${bBlue}Welcome to the Bittivirta Staff Key importer!${Color_Off}\n"
echo -e "${bBlue}Available users:${Color_Off}\n"

echo "$USERS" | jq -r '.[] | "\(.id). \(.username), \(.name)"' | tr -d '”'

echo -e "\n"
echo -ne "${Blue}Enter the user ID to import:${Color_Off} "
read key

USERNAME=$(echo "$USERS" | jq -r ".[] | select(.id == $key) | .username")
echo -e "${Blue}Downloading ${bBlue}$USERNAME${Blue}'s key..."

# Todo: The key gives an error about being invalid and it is not imported correctly. Fix this.

SSHKEYURL=$(echo "$USERS" | jq -r ".[] | select(.id == $key) | .keys")
SSHKEY=$(curl -s "$SSHKEYURL")

if [ -f ~/bittivirta-temp.pub ]; then
    rm ~/bittivirta-temp.pub
fi

echo -e "$SSHKEY bittivirta-key-$USERNAME" >> ~/bittivirta-temp.pub
chmod 600 ~/bittivirta-temp.pub

echo -e "${Blue}The key will be imported to the current user's authorized_keys files via ssh-add command.${Color_Off}\n"
echo -ne "${bBlue}Continue? (y/n)${Color_Off} "
read confirm

if [ "$confirm" != "y" ]; then
    echo -e "${bRed}Aborting...${Color_Off}"    §
    rm ~/bittivirta-temp.pub
    exit 1
fi


ssh-add -t 30 ~/bittivirta-temp.pub && SUCCESS=1
# rm ~/bittivirta-temp.pub

if [ "$SUCCESS" != 1 ]; then
    echo -e "${bRed}Error: ${Red}Failed to import the key!${Color_Off}"
    exit 1
fi

echo -e "${bGreen}Key imported successfully!${Color_Off}"

echo -e "\n${bRed}Warning: ${Red}Please remember to remove the key from the file when it is no longer needed!"
echo -e "         ${Red}If the key is not removed and the key is compromised, the attacker can access the server!"


