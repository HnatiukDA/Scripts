#!/bin/bash

# Check for root
if [[ "${UID}" -ne 0 ]]
then
    echo "You should run this script as a root!"
    exit 1
fi

# Set the number of days that user hasn't login
DAYS=30

CURRENT_DATE=$(date +%s)

# Loop through each user
for username in $(cut -d ':' -f1 /etc/passwd);
do
    LAST_LOGIN=$(lastlog -u $username | awk 'NR==2{print $4, $5, $6}')
    if [[ $LAST_LOGIN == "**Never**" ]]; then
        continue
    fi
    LAST_LOGIN_TIMESTAMP=$(date -d "$LAST_LOGIN" +%s)

    # Days since user last login
    DAYS_SINCE_LAST_LOGIN=$(((CURRENT_DATE - LAST_LOGIN_TIMESTAMP) / 86400))

    # Delete user if he hasn't logged in for the specified number of days
    if [[ $DAYS_SINCE_LAST_LOGIN -ge $DAYS ]]; then
        userdel -r $username
        echo "Deleted user account: $username"
    fi
done
exit 0
