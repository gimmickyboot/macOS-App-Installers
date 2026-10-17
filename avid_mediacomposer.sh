#!/bin/sh

downloadURL=""  # get this from within your Avid account

appInstallPath="/Applications/Avid Media Composer"
bundleName="AvidMediaComposer"
appName="${bundleName}"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleVersion 2>/dev/null)

currentVers=$(/usr/bin/curl -s "https://kb.avid.com/pkb/articles/en_US/Knowledge/en267087" | /usr/bin/grep -A 2 "Media Composer Version Matrix" | /usr/bin/xmllint --html --xpath '//*/tr[2]/td[2]/text()' - 2>/dev/null | /usr/bin/cut -c 3- - | /usr/bin/sed 's/[^0-9.]//g')
if [ ! "${currentVers}" ] || [ "${currentVers}" = "N/A" ]; then
  currentVers=$(/usr/bin/curl -s "https://kb.avid.com/pkb/articles/en_US/Knowledge/en267087" | /usr/bin/grep -A 2 "Media Composer Version Matrix" | /usr/bin/xmllint --html --xpath '//*/tr[2]/td[1]/text()' - 2>/dev/null | /usr/bin/cut -c 3- - | /usr/bin/sed 's/[^0-9.]//g')
  case "${currentVers}" in
    *.0)
      printf '%s\n' "Version ends in .0. Nothing to do"
      ;;

    *)
      currentVers="${currentVers}.0"
      ;;
  esac
fi

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
  /bin/rm -rf "${appInstallPath}"/"${bundleName}.app" >/dev/null 2>&1
  TMPDIR=$(mktemp -d)
  /usr/bin/hdiutil attach /tmp/"${FILE}" -noverify -quiet -nobrowse -mountpoint "${TMPDIR}"
  /usr/bin/find "${TMPDIR}" -name "*.pkg" -exec installer -pkg {} -target / \;
  /usr/bin/hdiutil eject "${TMPDIR}" -quiet
  /bin/rmdir "${TMPDIR}"
  /bin/rm /tmp/"${FILE}"
fi
