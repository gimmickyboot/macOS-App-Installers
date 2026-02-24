#!/bin/sh

appInstallPath="/Applications"
bundleName="R"
appName="${bundleName}"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

archType=$(uname -m)
URL="https://cran.rstudio.com/bin/macosx"
FILE=$(/usr/bin/curl -s "https://cran.rstudio.com/bin/macosx/" | /usr/bin/sed 's/<[^>]*>//g' | /usr/bin/grep "${archType}".pkg | /usr/bin/tail -n 1 | /usr/bin/sed 's/ //g')
currentVers=$(/bin/echo "${FILE}" | /usr/bin/awk -F - '{print $2}')
downloadURL="${URL}"/big-sur-"${archType}"/base/"${FILE}"
SHAHash=$(/usr/bin/curl -Ls "${URL}" | /usr/bin/sed 's/<[^>]*>//g' | /usr/bin/grep -A 1 "${FILE}" | /usr/bin/grep SHA1 | /usr/bin/tail -n 1 | /usr/bin/awk -F ";" '{print $2}')

# compare version numbers
if [ "${installedVers}" ]; then
  /bin/echo "${appName} v${installedVers} is installed."
  installedVersNoDots=$(/bin/echo "${installedVers}" | /usr/bin/sed 's/\.//g')
  currentVersNoDots=$(/bin/echo "${currentVers}" | /usr/bin/sed 's/\.//g')

  # pad out currentVersNoDots to match installedVersNoDots
  installedVersNoDotsCount=${#installedVersNoDots}
  currentVersNoDotsCount=${#currentVersNoDots}

  while [ "${currentVersNoDotsCount}" -lt "${installedVersNoDotsCount}" ]; do
    currentVersNoDots="${currentVersNoDots}0"
    currentVersNoDotsCount=$((currentVersNoDotsCount + 1))
  done

  if [ "${installedVersNoDots}" -ge "${currentVersNoDots}" ]; then
    /bin/echo "${appName} does not need to be updated"
    exit 0
  else
    /bin/echo "Updating ${appName} to v${currentVers}"
  fi
else
  /bin/echo "Installing ${appName} v${currentVers}"
fi

if /usr/bin/curl --retry 3 --retry-delay 0 --retry-all-errors -sL "${downloadURL}" -o /tmp/"${FILE}"; then
  # verify the hash
  SHAResult=$(/bin/echo "${SHAHash} */tmp/${FILE}" | /usr/bin/shasum -a 256 -c 2>/dev/null)
  case "${SHAResult}" in
    *OK)
      /bin/echo "SHA hash has successfully verifed."
      ;;

    *FAILED)
      /bin/echo "SHA hash has failed verification"
      exit 1
      ;;

    *)
      /bin/echo "An unknown error has occured."
      exit 1
      ;;
  esac
  /usr/sbin/installer -pkg /tmp/"${FILE}" -target /
  /bin/rm /tmp/"${FILE}"
fi
