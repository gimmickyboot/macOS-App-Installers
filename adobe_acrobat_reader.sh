#!/bin/sh

appInstallPath="/Applications"
bundleName="Adobe Acrobat Reader"
appName="${bundleName}"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleVersion 2>/dev/null)

currentVers=$(/usr/bin/curl -s https://armmf.adobe.com/arm-manifests/mac/AcrobatDC/reader/current_version.txt)
currentVersNoDots=$(printf '%s' "${currentVers}" | /usr/bin/sed 's/\.//g')
downloadURL="https://ardownload3.adobe.com/pub/adobe/acrobat/mac/AcrobatDC/${currentVersNoDots}/AdobeReader${currentVersNoDots}.dmg"
FILE=${downloadURL##*/}

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
      *.*)
        v1=${v1#*.}
        ;;
      *)
        v1=
        ;;
    esac

    case "$v2" in
      *.*)
        v2=${v2#*.}
        ;;
      *)
        v2=
        ;;
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
  TMPDIR=$(mktemp -d)
  if ! /usr/bin/hdiutil attach /tmp/"${FILE}" -noverify -quiet -nobrowse -mountpoint "${TMPDIR}"; then
    printf '%s\n' "Failed to mount ${FILE}"
    /bin/rmdir "${TMPDIR}"
    /bin/rm /tmp/"${FILE}"
    exit 1
  fi
  pkgPath=$(/usr/bin/find "${TMPDIR}" -name "*.pkg" -print -quit)
  if [ -z "${pkgPath}" ]; then
    printf '%s\n' "Could not find a PKG in mounted DMG"
    /usr/bin/hdiutil detach "${TMPDIR}" -quiet
    /bin/rmdir "${TMPDIR}"
    /bin/rm /tmp/"${FILE}"
    exit 1
  fi
  if ! /usr/sbin/installer -pkg "${pkgPath}" -target /; then
    printf '%s\n' "Failed to install ${pkgPath}"
    /usr/bin/hdiutil detach "${TMPDIR}" -quiet
    /bin/rmdir "${TMPDIR}"
    /bin/rm /tmp/"${FILE}"
    exit 1
  fi
  /usr/bin/hdiutil eject "${TMPDIR}" -quiet
  /bin/rmdir "${TMPDIR}"
  /bin/rm /tmp/"${FILE}"
fi
