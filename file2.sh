#!/bin/bash#!/bin/bash
#. ./database.sh "" ""
. ./encryption.sh "" ""

while true; do
  CHOICE=$(whiptail --title "Password Manager" --menu "How may I be of help today?" 15 60 5 \
    "1." "User Login (UID + Password)" \
    "2." "Add password for existing user" \
    "3." "Edit existing password" \
    "4." "Delete password" \
    "5." "Exit" 3>&1 1>&2 2>&3)

  case $CHOICE in
    "1.")
      Usnm=$(whiptail --title "User id input" --inputbox "Please enter your user id" 15 60 3>&1 1>&2 2>&3)
      encrypt "$Usnm"
      Pswd=$(whiptail --title "Password input" --passwordbox "Please enter your password" 15 60 3>&1 1>&2 2>&3)
      encrypt "$Pswd"
      
      whiptail --title "Entered Credentials" --msgbox "Username: $Usnm\nPassword: $Pswd" 10 50
      ;;
    "5.")
      clear
      exit 0
      ;;
  esac
done
