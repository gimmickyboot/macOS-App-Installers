#!/bin/sh

appInstallPath="/usr/local/bin"
bundleName="shellcheck"
installedVers=$("${appInstallPath}"/"${bundleName}" --version | /usr/bin/grep -E ^version | /usr/bin/awk '{print $2}')

gitHubURL="https://github.com/koalaman/shellcheck"
latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
latestReleaseTag=$(basename "${latestReleaseURL}")
currentVers=$(/bin/echo "${latestReleaseTag}" | /usr/bin/tr -d '[:alpha:]' | /usr/bin/sed 's/-//')
case $(uname -m) in
  arm64)
    archType="aarch64"
    ;;

  x86_64)
    archType="x86_64"
    ;;

  *)
    /bin/echo "Unknown processor architecture. Exiting"
    exit 1
    ;;
esac
downloadURL="${gitHubURL}/releases/download/${latestReleaseTag}/shellcheck-v${currentVers}.darwin.${archType}.tar.xz"
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
  /bin/rm "${appInstallPath}"/"${bundleName}" 2>/dev/null
  /usr/bin/tar -xvf /tmp/"${FILE}" -C /tmp/
  if [ ! -d "${appInstallPath}" ]; then
    /bin/mkdir -p "${appInstallPath}"
  fi
  /bin/mv /tmp/shellcheck-v"${currentVers}"/"${bundleName}" "${appInstallPath}"/"${bundleName}"
  /usr/bin/xattr -d com.apple.quarantine "${appInstallPath}"/"${bundleName}"
  /bin/chmod a+x "${appInstallPath}"/"${bundleName}"
  /bin/rm /tmp/"${FILE}"
fi
