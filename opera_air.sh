#!/bin/sh

appInstallPath="/Applications"
bundleName="Opera Air"
appName="${bundleName}"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleVersion 2>/dev/null)


currentVers=$(/usr/bin/curl -s "https://download3.operacdn.com/pub/opera_air/" | /usr/bin/sed -n 's|.*href="\([0-9][0-9.]*\)/".*|\1|p' | /usr/bin/sort -V | /usr/bin/tail -1)
case $(uname -m) in
  arm64)
    downloadURL="https://download3.operacdn.com/ftp/pub/opera_air/${currentVers}/mac/Opera_Air_${currentVers}_Autoupdate_arm64.tar.xz"
    SHAHash=$(/usr/bin/curl -s "https://download3.operacdn.com/pub/opera_air/${currentVers}/mac/Opera_Air_${currentVers}_Autoupdate_arm64.tar.xz.sha256sum")
    ;;

  x86_64)
    downloadURL="https://download3.operacdn.com/ftp/pub/opera_air/${currentVers}/mac/Opera_Air_${currentVers}_Autoupdate.tar.xz"
    SHAHash=$(/usr/bin/curl -s "https://download3.operacdn.com/pub/opera_air/${currentVers}/mac/Opera_Air_${currentVers}_Autoupdate.tar.xz.sha256sum")
    ;;

  *)
    printf '%s\n' "Unknown architecture. Exiting"
    exit 1
    ;;
esac
FILE=${downloadURL##*/}

# compare version numbers
if [ "${installedVers}" ]; then
  printf '%s\n' "${appName} v${installedVers} is installed."
  installedVersNoDots=$(printf '%s' "${installedVers}" | /usr/bin/sed 's/\.//g')
  currentVersNoDots=$(printf '%s' "${currentVers}" | /usr/bin/sed 's/\.//g')

  # pad out currentVersNoDots to match installedVersNoDots
  installedVersNoDotsCount=${#installedVersNoDots}
  currentVersNoDotsCount=${#currentVersNoDots}

  while [ "${currentVersNoDotsCount}" -lt "${installedVersNoDotsCount}" ]; do
    currentVersNoDots="${currentVersNoDots}0"
    currentVersNoDotsCount=$((currentVersNoDotsCount + 1))
  done

  if [ "${installedVersNoDots}" -ge "${currentVersNoDots}" ]; then
    printf '%s\n' "${appName} does not need to be updated"
    exit 0
  else
    printf '%s\n' "Updating ${appName} to v${currentVers}"
  fi
else
  printf '%s\n' "Installing ${appName} v${currentVers}"
fi

if /usr/bin/curl --retry 3 --retry-delay 0 --retry-all-errors -sL "${downloadURL}" -o /tmp/"${FILE}"; then
  SHAResult=$(printf '%s' "${SHAHash} */tmp/${FILE}" | /usr/bin/shasum -a 256 -c 2>/dev/null)
  case "${SHAResult}" in
    *OK)
      printf '%s\n' "SHA hash has successfully verifed."
      ;;

    *FAILED)
      printf '%s\n' "SHA hash has failed verification"
      exit 1
      ;;

    *)
      printf '%s\n' "An unknown error has occured."
      exit 1
      ;;
  esac
  /bin/rm -rf "${appInstallPath}"/"${bundleName}.app" >/dev/null 2>&1
  /usr/bin/tar -xf /tmp/${FILE} -C "${appInstallPath}"/
  /usr/bin/xattr -r -d com.apple.quarantine "${appInstallPath}"/"${bundleName}.app"
  /usr/sbin/chown -R root:admin "${appInstallPath}"/"${bundleName}.app"
  /bin/chmod -R 755 "${appInstallPath}"/"${bundleName}.app"
  /bin/rm /tmp/"${FILE}"
fi
