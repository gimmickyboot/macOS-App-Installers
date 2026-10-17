#!/bin/sh

appInstallPath="/Applications"
bundleName="DisplayLink Manager"
appName="${bundleName}"
installedVers=$(/usr/bin/defaults read "${appInstallPath}"/"${bundleName}.app"/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)

URL="https://www.synaptics.com"
currentVers=$(/usr/bin/curl -sL "${URL}/products/displaylink-graphics/downloads/macos" | /usr/bin/grep "Release" | /usr/bin/head -n 1 | /usr/bin/sed -n 's/.*Release: \([^ ]*\).*/\1/p')
releaseDate=$(/usr/bin/curl -sL "${URL}/products/displaylink-graphics/downloads/macos" | /usr/bin/grep "Release Notes" | /usr/bin/grep "${currentVers}" | /usr/bin/xmllint --html --xpath 'string(//a/@href)' - | /usr/bin/awk -F "/" '{print $6}')
downloadURL="${URL}/sites/default/files/exe_files/${releaseDate}/DisplayLink%20Manager%20Graphics%20Connectivity${currentVers}-EXE.pkg"
FILE=${downloadURL##*/}
LSEURL="https://www.displaylink.com/downloads/macos_extension"
TMPLSEURL=$(/usr/bin/curl -sI "${LSEURL}" | /usr/bin/grep -i "^Location" | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
LSEFILE=${TMPLSEURL##*/}

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
  if ! installResult=$(/usr/sbin/installer -pkg /tmp/"${FILE}" -target / 2>&1); then
    printf '%s\n' "An error occurred installing ${FILE}:"
    printf '%s\n' "${installResult}"
  else
    printf '%s\n' "Successfully installed ${FILE}"
  fi
  /bin/rm /tmp/"${FILE}"
fi
if /usr/bin/curl --retry 3 --retry-delay 0 --retry-all-errors -sL "${TMPLSEURL}" -o /tmp/"${LSEFILE}"; then
  TMPDIR=$(mktemp -d)
  /usr/bin/hdiutil attach /tmp/"${LSEFILE}" -noverify -quiet -nobrowse -mountpoint "${TMPDIR}"
  /usr/bin/find "${TMPDIR}" -name "*.pkg" -exec /usr/sbin/installer -pkg {} -target / \;
  /usr/bin/hdiutil eject "${TMPDIR}" -quiet
  /bin/rmdir "${TMPDIR}"
  /bin/rm /tmp/"${LSEFILE}"
fi
