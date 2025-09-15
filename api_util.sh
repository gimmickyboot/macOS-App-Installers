#!/bin/sh

appInstallPath="/Applications"
bundleName="API Utility"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

gitHubURL="https://github.com/Jamf-Concepts/apiutil"
latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
latestReleaseTag=$(basename "${latestReleaseURL}")
currentVers=$(/bin/echo "${latestReleaseTag}" | /usr/bin/sed 's/v//')
downloadURL="${gitHubURL}/releases/download/${latestReleaseTag}/API.Utility.zip"
FILE=${downloadURL##*/}

# compare version numbers
if [ "${installedVers}" ]; then
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
    /bin/echo "${bundleName} does not need to be updated"
    exit 0
  else
    /bin/echo "${bundleName} needs to be updated"
  fi
else
  /bin/echo "Installing ${bundleName}"
fi

if /usr/bin/curl --retry 3 --retry-delay 0 --retry-all-errors -sL "${downloadURL}" -o /tmp/"${FILE}"; then
  /bin/rm -rf "${appInstallPath}"/"${bundleName}.app" >/dev/null 2>&1
  /usr/bin/ditto -xk /tmp/"${FILE}" "${appInstallPath}"/.
  /usr/bin/xattr -r -d com.apple.quarantine "${appInstallPath}"/"${bundleName}.app"
  /usr/sbin/chown -R root:admin "${appInstallPath}"/"${bundleName}.app"
  /bin/chmod -R 755 "${appInstallPath}"/"${bundleName}.app"
  /bin/rm /tmp/"${FILE}"
fi

if [ ! "${installedVers}" ]; then
  CurrentlyLoggedInUser=$(stat -f %Su /dev/console)
  currentUserShell=$(/usr/bin/dscl . -read /Users/"${CurrentlyLoggedInUser}" UserShell | /usr/bin/awk '{print $2}')
  case "${currentUserShell}" in
    *zsh*)
      printf '\n%s\n' "alias apiutil=\"/Applications/API\ Utility.app/Contents/MacOS/apiutil\"" >> "${CurrentlyLoggedInUser}"/.zshrc
      ;;

    *bash*)
      printf '\n%s\n' "alias apiutil=\"/Applications/API\ Utility.app/Contents/MacOS/apiutil\"" >> "${CurrentlyLoggedInUser}"/.bash_profile
      ;;

    *)
      /bin/echo "Unknown shell."
      ;;
  esac
fi
