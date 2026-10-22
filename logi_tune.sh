#!/bin/sh

# requires /usr/bin/jq

appInstallPath="/Applications"
bundleName="Logi Tune"
appName="${bundleName}"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

downloadURL="https://software.vc.logitech.com/downloads/tune/LogiTuneInstaller.dmg"
FILE=${downloadURL##*/}
pageURL=$(/usr/bin/curl -s "https://support.logi.com/api/v2/help_center/en-us/articles.json?label_names=webcontent=productdownload,webos=mac-macos-x-11.0" | /usr/lbin/jq -r '.articles | map(select(.name == "Logi Tune")) | .[0] | .html_url')
currentVers=$(/usr/bin/curl -s "${pageURL}" | /usr/bin/grep "Software Version" | /usr/bin/head -n 1 | /usr/bin/sed 's/[^0-9.]//g')

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
  if [ ! -f "${TMPDIR}"/LogiTuneInstaller.app/Contents/Resources/Applications/LogiTune.tgz ]; then
    printf '%s\n' "Could not find LogiTune.tgz in mounted DMG"
    /usr/bin/hdiutil detach "${TMPDIR}" -quiet
    /bin/rmdir "${TMPDIR}"
    /bin/rm /tmp/"${FILE}"
    exit 1
  fi
  /usr/bin/tar zxf "${TMPDIR}"/LogiTuneInstaller.app/Contents/Resources/Applications/LogiTune.tgz -C "${appInstallPath}"/
  /usr/bin/xattr -r -d com.apple.quarantine "${appInstallPath}"/"${bundleName}.app"
  /usr/sbin/chown -R root:admin "${appInstallPath}"/"${bundleName}.app"
  cd "${TMPDIR}"/LogiTuneInstaller.app/Contents/Resources || exit
  sh application-scripts/postinstall
  /usr/bin/hdiutil eject "${TMPDIR}" -quiet
  /bin/rmdir "${TMPDIR}"
  /bin/rm /tmp/"${FILE}"
fi
