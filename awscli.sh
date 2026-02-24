#!/bin/sh

appInstallPath="/usr/local/bin"
bundleName="aws"
appName="${bundleName}"
installedVers=$("${appInstallPath}/${bundleName}" --version | /usr/bin/awk -F "/" '{print $2}' | /usr/bin/awk '{print $1}' 2>/dev/null)

currentVers=$(/usr/bin/curl -s "https://raw.githubusercontent.com/aws/aws-cli/v2/CHANGELOG.rst" | /usr/bin/grep ^2\. | /usr/bin/sort -V | /usr/bin/tail -n 1)
downloadURL="https://awscli.amazonaws.com/AWSCLIV2.pkg"
FILE=${downloadURL##*/}

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
  /usr/sbin/installer -pkg /tmp/"${FILE}" -target /
  /bin/rm /tmp/"${FILE}"
fi
