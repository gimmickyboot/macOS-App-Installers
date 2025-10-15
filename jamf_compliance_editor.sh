#!/bin/sh

appInstallPath="/Applications"
bundleName="Jamf Compliance Editor"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

gitHubURL="https://github.com/Jamf-Concepts/jamf-compliance-editor"
latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
latestReleaseTag=$(basename "${latestReleaseURL}")
currentVers=$(/bin/echo "${latestReleaseTag}" | /usr/bin/sed 's/v//')
case $(/bin/echo "${currentVers}" | /usr/bin/grep -o '\.' | /usr/bin/wc -l | /usr/bin/xargs) in
  1)
    actualVers="${currentVers}.0"
    ;;

  *)
    actualVers="${currentVers}"
    ;;
esac
downloadURL="${gitHubURL}/releases/download/${latestReleaseTag}/JamfComplianceEditor-${actualVers}.pkg"
FILE=${downloadURL##*/}
SHAHash=$(/usr/bin/curl -sL "$(/bin/echo "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/awk "f&&/sha256:/{print; exit} /${FILE}/{f=1}"| /usr/bin/sed -E 's/.*sha256:([0-9a-fA-F]{64}).*/\1/')

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
