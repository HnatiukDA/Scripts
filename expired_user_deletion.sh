#!/bin/bash

# This script takes everyone with id>1000 from /etc/passwd and removes every user account in case if it hasn't been used for the last 30 days.

# Make sure that script is being executed with root priviligies.

if [[ "${UID}" -ne 0 ]]
then
echo "You should run this script as a root!"
exit 1
fi

# First of all we need to know id limit (min & max)

USER_UID_MIN=$(grep "^UID_MIN" /etc/login.defs)

USER_UID_MAX=$(grep "^UID_MAX" /etc/login.defs)

# Print all users accounts with id>=1000 and <=6000 (default).

awk -F':' -v "min=${USER_MIN##UID_MIN}" -v "max=${USER_MAX##UID_MAX}" ' { if ( $3 >= min && $3 <= max ) print $0}' /etc/passwd

# This function deletes users which hasn't log in in the last 30 days

# Make a color output message

for accounts in ` lastlog -b 30 | sed "1d" | awk ' { print $1 } '`

do

userdel $accounts 2>/dev/null

done

echo -e "\e[36mYou have successfully deleted all user's account which nobody logged in in the past 30 days.\e[0,"

exit 0
