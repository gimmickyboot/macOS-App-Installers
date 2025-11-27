#!/bin/sh

appInstallPath="/usr/local/bin"
bundleName="jq"
# shellcheck disable=SC1001
installedVers=$("${appInstallPath}/${bundleName}" --version | /usr/bin/cut -d \- -f 2- -)

gitHubURL="https://github.com/jqlang/jq"
latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
latestReleaseTag=$(basename "${latestReleaseURL}")
case "$(uname -m)" in
  arm64)
    myArch="arm64"
    ;;

  x86_64)
    myArch="amd64"
    ;;

  *)
    /bin/echo "Unknown processor architecture. Exiting"
    exit 1
    ;;
esac
# shellcheck disable=SC1001
currentVers=$(/bin/echo "${latestReleaseTag}" | /usr/bin/cut -d \- -f 2- -)
downloadURL="${gitHubURL}/releases/download/${latestReleaseTag}/jq-macos-${myArch}"
FILE="${bundleName}"
SHAHash=$(/usr/bin/curl -sL "$(/bin/echo "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/awk "f&&/sha256:/{print; exit} /${FILE}/{f=1}"| /usr/bin/sed -E 's/.*sha256:([0-9a-fA-F]{64}).*/\1/')

# compare version numbers
if [ "${installedVers}" ]; then
  /bin/echo "${bundleName} v${installedVers} is installed."
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
    /bin/echo "Updating ${bundleName} to v${currentVers}"
  fi
else
  /bin/echo "Installing ${bundleName} v${currentVers}"
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
  /bin/mv /tmp/"${FILE}" "${appInstallPath}"/
  /usr/bin/xattr -r -d com.apple.quarantine "${appInstallPath}"/"${bundleName}"
  /usr/sbin/chown root:wheel "${appInstallPath}"/"${FILE}"
  /bin/chmod 755 "${appInstallPath}"/"${FILE}"
fi
