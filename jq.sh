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
  /bin/rm -rf "${appInstallPath:?}"/"${bundleName}" >/dev/null 2>&1
  /bin/mv /tmp/"${FILE}" "${appInstallPath}"/
  /usr/sbin/chown root:wheel "${appInstallPath}"/"${FILE}"
  /bin/chmod 755 "${appInstallPath}"/"${FILE}"
fi
