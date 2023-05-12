#!/bin/bash

# Check for root
if [[ "${UID}" -ne 0 ]]
then
    echo "You should run this script as a root!"
    exit 1
fi

# Set the number of days that user hasn't login
DAYS=30

BACKUP_EXPIRED_DAYS=14

CURRENT_DATE=$(date +%s)

BACKUP_DIR="/opt/backup/delited_users_directories"


# Backing up user directoory
function backup_user_folder() {
    if [ -d "$1" ]; then
        if [ ! -d $BACKUP_DIR ]; then
            mkdir -p $BACKUP_DIR
        fi
        mv "$1" $BACKUP_DIR/
    fi
}

# Remove old backup directories
function remove_old_backup() {
    for dirname in "$BACKUP_DIR"/*;
    do
        [[ -d "$dirname" ]] || continue # Handle if it not a dir

        DIR_CHANGE_TIMESTAMP="$(date -d "$(stat "$dirname" | grep "Change" | awk \
        '{print $2}')" +%s)"
        # Days since dir was created
        DAYS_SINCE_DIR_CHANGE=$(((CURRENT_DATE - DIR_CHANGE_TIMESTAMP) / 86400))

        # Delete expired backup
        if [[ $DAYS_SINCE_DIR_CHANGE -ge $BACKUP_EXPIRED_DAYS ]]; then
            rm -rf ${BACKUP_DIR:?}/"$dirname"
        fi
    done
}

# Loop through each user
for username in $(cut -d ':' -f1 /etc/passwd);
do
    LAST_LOGIN=$(lastlog -u "$username" | awk 'NR==2{print $4, $5, $6}')
    # Check if user never login
    if [[ $(lastlog -u "$username" | awk 'NR==2{print}') == *"**Never"* ]]; then
        # echo -e "$username - Never loged in"
        continue
    fi
    LAST_LOGIN_TIMESTAMP=$(date -d "$LAST_LOGIN" +%s)
    if [[ $LAST_LOGIN_TIMESTAMP = 0 ]]; then
        continue
    fi
    # Days since user last login
    DAYS_SINCE_LAST_LOGIN=$(((CURRENT_DATE - LAST_LOGIN_TIMESTAMP) / 86400))

    # Delete user if he hasn't logged in for the specified number of days
    if [[ $DAYS_SINCE_LAST_LOGIN -ge $DAYS ]]; then
        backup_user_folder "/home/$username"
        userdel -r "$username"
        echo "Deleted user account: $username"
    fi
done

remove_old_backup
exit 0
