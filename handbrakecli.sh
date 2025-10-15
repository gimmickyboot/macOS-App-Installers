#!/bin/sh

appInstallPath="/usr/local/bin"
bundleName="HandBrakeCLI"
installedVers=$(/usr/local/bin/HandBrakeCLI --version 2>/dev/null | grep HandBrake | awk '{print $2}')

gitHubURL="https://github.com/handbrake/handbrake"
latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
latestReleaseTag=$(basename "${latestReleaseURL}")
currentVers=$(/bin/echo "${latestReleaseTag}" | /usr/bin/tr -d '[:alpha:]' | /usr/bin/sed 's/-//')
downloadURL="${gitHubURL}/releases/download/${latestReleaseTag}/HandBrakeCLI-${currentVers}.dmg"
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
  /bin/rm -rf "${appInstallPath:?}"/"${bundleName}" >/dev/null 2>&1
  TMPDIR=$(mktemp -d)
  /usr/bin/hdiutil attach /tmp/"${FILE}" -noverify -quiet -nobrowse -mountpoint "${TMPDIR}"
  /usr/bin/ditto "${TMPDIR}"/"${bundleName}" "${appInstallPath}"/"${bundleName}"
  /usr/bin/xattr -r -d com.apple.quarantine "${appInstallPath}"/"${bundleName}"
  /usr/sbin/chown -R root:admin "${appInstallPath}"/"${bundleName}"
  /bin/chmod -R 755 "${appInstallPath}"/"${bundleName}"
  /usr/bin/hdiutil eject "${TMPDIR}" -quiet
  /bin/rmdir "${TMPDIR}"
  /bin/rm /tmp/"${FILE}"
fi
