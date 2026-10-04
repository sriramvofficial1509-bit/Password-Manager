#!/bin/bash

# Missing space after "Password" before 3>&1
NAME=$(whiptail --title "Password Manager" --inputbox "What is your username?" 8 45 "" 3>&1 1>&2 2>&3)

# Fix spacing inside [ ... ]: MUST have spaces inside brackets
if [ "$?" -eq 0 ]; then
    whiptail --msgbox "Username: $NAME " 8 45
else
   whiptail --msgbox "Operation cancelled by User" 8 45
fi
