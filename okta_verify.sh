#!/bin/sh

adminDomain=""  # eg busname-admin.okta.com
ssoURL=""  # eg sso.busname.domain.com

appInstallPath="/Applications"
bundleName="Okta Verify"
appName="${bundleName}"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

jSON=$(/usr/bin/curl -s "https://${adminDomain}/api/v1/artifacts/OKTA_VERIFY_MACOS/latest?releaseChannel=GA")
if [ "$(/usr/bin/sw_vers -buildVersion | /usr/bin/cut -c 1-2 -)" -ge 24 ]; then
  currentVers=$(/bin/echo "${jSON}" | /usr/bin/jq -r .version)
  downloadURL="https://${ssoURL}$(/bin/echo "${jSON}" | /usr/bin/jq -r '.files[].href')"
  SHAHash=$(/bin/echo "${jSON}" | /usr/bin/jq -r '.files[].fileHashes."SHA-256"')
else
  currentVers=$(/bin/echo "${jSON}" | /usr/bin/plutil -extract version raw -o - -)
  downloadURL="https://${ssoURL}$(/bin/echo "${jSON}" | plutil -extract files.0.href raw -o - -)"
  SHAHash=$(/bin/echo "${jSON}" | /usr/bin/plutil -extract files.0.fileHashes.SHA-256 raw -o - -)
fi
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
