#!/bin/sh

appInstallPath="/Applications"
bundleName="MySQLWorkbench"
appName="${bundleName}"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null | /usr/bin/sed 's/\.CE$//')

currentVers=$(/usr/bin/curl -fsL "https://dev.mysql.com/downloads/workbench/?os=33" | /usr/bin/grep -A1 "DMG Archive" | /usr/bin/tail -n 1 | /usr/bin/awk -F'[<>]' '{print $3}')
case $(uname -m) in
  arm64)
    archType="arm64"
    ;;

  x86_64)
    archType="x86_64"
    ;;

  *)
    printf '%s\n' "Unknown processor architecture. Exiting"
    exit 1
    ;;
esac
downloadURL="https://cdn.mysql.com//Downloads/MySQLGUITools/$(/usr/bin/curl -fsL "https://dev.mysql.com/downloads/workbench/?os=33" | /usr/bin/grep -o "mysql-workbench-community-.*-macos-${archType}.dmg" | /usr/bin/head -n1)"
FILE=${downloadURL##*/}
MD5Hash=$(/usr/bin/curl -fsL "https://dev.mysql.com/downloads/workbench/?os=33" | /usr/bin/grep -A3 "${FILE}" | /usr/bin/grep MD5 | /usr/bin/awk -F'[<>]' '{print $3}')

# compare version numbers
if [ -n "${installedVers}" ]; then
  printf '%s\n' "${appName} v${installedVers} is installed."

  # Sanitise version strings, retaining only numbers and dots
  v1=$(printf '%s' "${installedVers}" | /usr/bin/sed 's/[^0-9.]//g')
  v2=$(printf '%s' "${currentVers}" | /usr/bin/sed 's/[^0-9.]//g')

  while :; do
    # Extract the next version component
    n1=${v1%%.*}
    n2=${v2%%.*}

    # Remove the component just compared
    case "$v1" in
      *.*) v1=${v1#*.} ;;
      *)   v1= ;;
    esac

    case "$v2" in
      *.*) v2=${v2#*.} ;;
      *)   v2= ;;
    esac

    # Treat missing components as zero
    n1=${n1:-0}
    n2=${n2:-0}

    if [ "$n1" -gt "$n2" ]; then
      # Installed version is newer
      break
    elif [ "$n1" -lt "$n2" ]; then
      # Installed version is older
      break
    fi

    # Versions are equal
    [ -z "$v1" ] && [ -z "$v2" ] && break
  done

  if [ "$n1" -ge "$n2" ]; then
    printf '%s\n' "${appName} does not need to be updated"
    exit 0
  else
    printf '%s\n' "Updating ${appName} to v${currentVers}"
  fi
else
  printf '%s\n' "Installing ${appName} v${currentVers}"
fi

if /usr/bin/curl --retry 3 --retry-delay 0 --retry-all-errors -sL "${downloadURL}" -o /tmp/"${FILE}"; then
  MD5Hash=$(printf '%s' "${MD5Hash} */tmp/${FILE}" | /sbin/md5sum -c - 2>/dev/null)
  case "${MD5Hash}" in
    *OK)
      printf '%s\n' "MD5 hash has successfully verifed."
      ;;

    *WARNING)
      printf '%s\n' "MD5 hash has failed verification"
      exit 1
      ;;

    *)
      printf '%s\n' "An unknown error has occured."
      exit 1
      ;;
  esac
  /bin/rm -rf "${appInstallPath}"/"${bundleName}.app" >/dev/null 2>&1
  TMPDIR=$(mktemp -d)
  /usr/bin/hdiutil attach /tmp/"${FILE}" -noverify -quiet -nobrowse -mountpoint "${TMPDIR}"
  /usr/bin/ditto "${TMPDIR}"/"${bundleName}.app" "${appInstallPath}"/"${bundleName}.app"
  /usr/bin/xattr -r -d com.apple.quarantine "${appInstallPath}"/"${bundleName}.app"
  /usr/sbin/chown -R root:admin "${appInstallPath}"/"${bundleName}.app"
  /bin/chmod -R 755 "${appInstallPath}"/"${bundleName}.app"
  /usr/bin/hdiutil eject "${TMPDIR}" -quiet
  /bin/rmdir "${TMPDIR}"
  /bin/rm /tmp/"${FILE}"
fi
