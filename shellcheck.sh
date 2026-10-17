#!/bin/sh

appInstallPath="/usr/local/bin"
bundleName="shellcheck"
appName="${bundleName}"
installedVers=$("${appInstallPath}"/"${bundleName}" --version | /usr/bin/grep -E ^version | /usr/bin/awk '{print $2}')

gitHubURL="https://github.com/koalaman/shellcheck"
latestReleaseURL=$(/usr/bin/curl -sI "${gitHubURL}/releases/latest" | /usr/bin/grep -i ^location | /usr/bin/awk '{print $2}' | /usr/bin/sed 's/\r//g')
currentVers=$(basename "${latestReleaseURL}" | /usr/bin/tr -d '[:alpha:]' | /usr/bin/sed 's/-//')
case $(uname -m) in
  arm64)
    archType="aarch64"
    ;;

  x86_64)
    archType="x86_64"
    ;;

  *)
    printf '%s\n' "Unknown processor architecture. Exiting"
    exit 1
    ;;
esac
downloadURL="https://github.com$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/grep "darwin.${archType}.tar.xz" | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//a/@href)' -)"
FILE=${downloadURL##*/}
SHAHash=$(/usr/bin/curl -sL "$(printf '%s' "${latestReleaseURL}" | /usr/bin/sed 's/tag/expanded_assets/')" | /usr/bin/awk "f&&/sha256:/{print; exit} /${FILE}/{f=1}"| /usr/bin/sed -E 's/.*sha256:([0-9a-fA-F]{64}).*/\1/')

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
  /bin/rm "${appInstallPath}"/"${bundleName}" 2>/dev/null
  /usr/bin/tar -xf /tmp/"${FILE}" -C /tmp/
  if [ ! -d "${appInstallPath}" ]; then
    /bin/mkdir -p "${appInstallPath}"
  fi
  /bin/mv /tmp/shellcheck-v"${currentVers}"/"${bundleName}" "${appInstallPath}"/"${bundleName}"
  /usr/bin/xattr -d com.apple.quarantine "${appInstallPath}"/"${bundleName}" 2>/dev/null
  /bin/chmod a+x "${appInstallPath}"/"${bundleName}"
  /bin/rm /tmp/"${FILE}"
  /bin/rm /tmp/shellcheck-v"${currentVers}"
fi
