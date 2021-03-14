#!/bin/bash

# This script archives, disables, and/or deletes local user accounts.

readonly ARCHIVE_DIR='/archive'

usage() {
  # Display the usage and exit.
  echo "Usage: ${0} [-dra] USER [USER]..." >&2
  echo 'Disable a local Linux account.' >&2
  echo ' -d Deletes accounts instead of disabling them.' >&2
  echo ' -r Removes the associated home directory.' >&2
  echo ' -a Archives the associated home directory.' >&2
  exit 1
}

if [[ "${UID}" -ne 0 ]]
then
  echo 'Please run this script as root.'
  exit 1
fi

while getopts dra OPTION
do
  case ${OPTION} in
    d)
      DELETE='true' ;;
    r)
      REMOVE_DIR='-r' ;;
    a)
      ARCHIVING='true' ;;
    ?) usage ;;
  esac
  shift "$(( OPTIND -1 ))"
done

if [[ "${#}" -lt 1 ]]
then
  usage
fi

for USERNAME in "${@}"
do
  echo "Processing user: ${USERNAME}"

  # Avoid deleting system accounts.
  USERID=$(id -u ${USERNAME})
  if [[ "${USERID}" -lt 1000 ]]
  then
    echo "Not deleting ${USERNAME} with userid ${USERID}." >&2
    exit 1
  fi

  if [[ "${ARCHIVING}" = 'true' ]]
  then
    if [[ ! -d "${ARCHIVE_DIR}" ]]
    then
      echo "Creating ${ARCHIVE_DIR}..."
      mkdir -p ${ARCHIVE_DIR}
      if [[ "${?}" -ne 0 ]]
      then
        echo "The archive directory ${ARCHIVE_DIR} could not be created." >&2
        exit 1
      fi
    fi

    HOME_DIR="/home/${USERNAME}"
    ARCHIVE_FILE="${ARCHIVE_DIR}/${USERNAME}.tgz"
    if [[ -d "${HOME_DIR}" ]]
    then
      echo "Archiving ${HOME_DIR} to ${ARCHIVE_FILE}"
      tar -zcf ${ARCHIVE_FILE} ${HOME_DIR} &> /dev/null
      if [[ "${?}" -ne 0 ]]
      then
        echo "Could not create ${ARCHIVE_FILE}." >&2
        exit 1
      fi
    else
      echo "${HOME_DIR} does not exist or is not a directory." >&2
      exit 1
    fi
  fi

  if [[ "${DELETE}" = 'true' ]]
  then
    userdel ${REMOVE_DIR} ${USERNAME}
    if [[ "${?}" -ne 0 ]]
    then
      echo "The account ${USERNAME} was NOT deleted." >&2
      exit 1
    fi
    echo "The account ${USERNAME} was deleted."
  else
    chage -E 0 ${USERNAME}
    if [[ "${?}" -ne 0 ]]
    then
      echo "The account ${USERNAME} was NOT disabled." >&2
      exit 1
    fi
    echo "The account ${USERNAME} was disabled."
  fi
done

exit 0