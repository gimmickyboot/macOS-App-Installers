#!/bin/sh

appInstallPath="/usr/local/share/dotnet/sdk"
bundleName=".Net SDK 9 STS"
appName="${bundleName}"
installedVers=$(/usr/bin/find "${appInstallPath}" -mindepth 1 -maxdepth 1 -type d -name '9*' -exec basename {} \; | /usr/bin/sort -V | /usr/bin/tail -n 1)

case $(arch) in
  arm64)
    archType="arm64"
    ;;

  x86_64)
    archType="x64"
    ;;

  *)
    printf '%s\n' "Unknown architecture. Exiting"
    exit 1
    ;;
esac

htmlData=$(/usr/bin/curl -s "https://dotnet.microsoft.com/en-us/download/dotnet/9.0")
currentVers=$(printf '%s' "${htmlData}" | /usr/bin/awk '/sdk-/ && !found { print; found = 1 }' | /usr/bin/head -n 1 | /usr/bin/xmllint --html --xpath 'string(//h3/text())' - - 2>/dev/null| /usr/bin/awk '{print $2}')
downloadURLTMP=$(printf '%s' "${htmlData}" | /usr/bin/grep "sdk-${currentVers}-macos-${archType}-installer" | /usr/bin/xmllint --html --xpath 'string(//a/@href)' - - 2>/dev/null)
htmlDataTMP=$(/usr/bin/curl -s "https://dotnet.microsoft.com${downloadURLTMP}")
downloadURL=$(printf '%s' "${htmlDataTMP}" | /usr/bin/grep pkg | /usr/bin/xmllint --html --xpath 'string(//a/@href)' - - 2>/dev/null)
FILE=${downloadURL##*/}
SHAHash=$(printf '%s' "${htmlDataTMP}" | /usr/bin/grep -A 2 SHA512 | /usr/bin/xmllint --html --xpath 'string(//input/@value)' - 2>/dev/null)

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
  SHAResult=$(printf '%s' "${SHAHash} */tmp/${FILE}" | /usr/bin/shasum -a 512 -c 2>/dev/null)
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
  if ! installResult=$(/usr/sbin/installer -pkg /tmp/"${FILE}" -target / 2>&1); then
    printf '%s\n' "An error occurred installing ${FILE}:"
    printf '%s\n' "${installResult}"
  else
    printf '%s\n' "Successfully installed ${FILE}"
  fi
  /bin/rm /tmp/"${FILE}"
fi
