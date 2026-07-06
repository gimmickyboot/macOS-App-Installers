from urllib.parse import urlparse, urlsplit

import json
import re
import subprocess

from bs4 import BeautifulSoup
import requests

from models import App, Result
from helpers import (
    get_text,
    get_json,
    get_xml,
    get_plist,
    get_yaml,
    get_redirect_url,
    get_redirect_url_curl,
    get_href_link,
    filename_from_url,
    extract_version,
    validate_download_url,
)
import config as cfg


def scrape_sparkle(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    if not app.sparkle_version_key:
        raise ValueError("sparkle_version_key is required")

    xml = get_xml(app.app_url, session)

    item = xml.find(".//channel/item")
    if item is None:
        raise ValueError("Could not find Sparkle item")

    enclosure = xml.find('.//channel/item/enclosure')
    if enclosure is None:
        raise ValueError("Could not find enclosure")

    ns = {
        'sparkle': 'http://www.andymatuschak.org/xml-namespaces/sparkle'
    }

    sparkle_ns = ns['sparkle']
    version_raw = f"{{{sparkle_ns}}}{app.sparkle_version_key}"

    version = enclosure.get(version_raw)
    if not version:
        version = item.findtext(f"sparkle:{app.sparkle_version_key}", namespaces=ns)

    if not version:
        raise ValueError("Could not determine version")

    download_url = enclosure.get('url')
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_onepassword(session: requests.Session, app: App) -> Result:
    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    content = soup.find("div", class_="u-flexgrow u-text-left")
    if not content:
        raise ValueError("Could not find version div")

    text = content.get_text(" ", strip=True)

    version_raw = re.search(r"Updated to\s+([^\s]+)", text).group(1)
    version = version_raw.split("-")[0]
    if not version:
        raise ValueError("Could not determine version")

    download_url = app.download_url

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_adobeacrobatreader(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    if not app.download_url_template:
        raise ValueError("download_url_template is required")

    text = get_text(app.app_url, session)

    version = text
    if not version:
        raise ValueError("Could not determine version")

    version_no_dots = version.replace(".", "")

    download_url = app.download_url_template.format(version=version_no_dots)
    if not download_url:
        raise ValueError("Could not determine download_url")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_androidstudio(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    download_url_raw = soup.find('a', href=re.compile(r'mac_arm\.dmg', re.IGNORECASE))
    download_url = download_url_raw['href']

    path = urlparse(download_url).path
    segments = [segment for segment in path.split('/') if segment]
    second_to_last = segments[-2]
    parts = second_to_last.split('.')
    version = '.'.join(parts[:2])
    if not version:
        raise ValueError("Could not determine version")

    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_atext(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    pattern = re.compile(r'Version\s+(\d+(?:\.\d+)*).*macOS', re.IGNORECASE)
    versions = [
        pattern.search(p.get_text()).group(1)
        for p in soup.find_all('p')
        if pattern.search(p.get_text())
    ]
    version = versions[-1] if versions else None
    if not version:
        raise ValueError("Could not determine version")

    links = soup.find_all('a', href=True)
    for link in links:
        if ".dmg" in link['href']:
            download_url_raw = link['href']
            break

    download_url = f"{app.app_url}/{download_url_raw}"
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_avidlink(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    script_tag = soup.find("script", type="application/json")
    if script_tag:
        try:
            json_data = json.loads(script_tag.string)

            # Recursive function that stops and returns immediately on the first match
            def find_first_pkg(data):
                if isinstance(data, dict):
                    for value in data.values():
                        result = find_first_pkg(value)
                        if result:
                            return result
                elif isinstance(data, list):
                    for item in data:
                        result = find_first_pkg(item)
                        if result:
                            return result
                elif isinstance(data, str) and "pkg" in data.lower():
                    return data
                return None

            # Extract and print the single result
            download_url = find_first_pkg(json_data)

        except json.JSONDecodeError:
            print("Error: Invalid JSON inside the script tag.")
    else:
        print("Error: Script tag not found.")

    file_name = filename_from_url(download_url)
    version = extract_version(file_name)
    if not version:
        raise ValueError("Could not determine version")

    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_awscli(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)

    version = extract_version(html)
    if not version:
        raise ValueError("Could not determine version")

    download_url = app.download_url

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_blender(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    download_url = get_href_link(soup, "macos-arm64.dmg").strip('/')

    file_name = filename_from_url(download_url)
    version = extract_version(file_name)
    if not version:
        raise ValueError("Could not determine version")

    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_bbedit(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    download_url = get_href_link(soup, ".dmg")
    file_name = filename_from_url(download_url)
    version = extract_version(file_name)
    if not version:
        raise ValueError("Could not determine version")

    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_github(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    latest_release_html = get_text(f"{app.app_url}/releases/latest", session)
    latest_release_soup = BeautifulSoup(latest_release_html, "html.parser")

    release_tag_url_results = latest_release_soup.find("meta", attrs={"name": "apple-itunes-app"})
    if not release_tag_url_results:
        raise ValueError("Could not find release tag results")

    content = release_tag_url_results.get("content", "")
    tag = None
    for item in content.split(", "):
        if item.startswith("app-argument="):
            release_tag_url = item.split("=", 1)[1]
            tag = release_tag_url.split("/")[-1]
            version = re.sub(r'[^0-9.]', '', tag)
            break

    if not tag:
        raise ValueError("Could not determine release tag")

    download_url_html = get_text(f"{app.app_url}/releases/expanded_assets/{tag}", session)
    download_soup = BeautifulSoup(download_url_html, "html.parser")
    download_url_raw = None

    for link in download_soup.find_all("a", href=True):
        link_href = link["href"].lower()

        if all(s.lower() in link_href for s in app.file_search_strings):
            download_url_raw = link["href"]
            break

    if not download_url_raw:
        raise ValueError("Could not find download link")
    download_url = requests.compat.urljoin("https://github.com", download_url_raw)

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_microsoft_plist(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    plist_data_raw = get_plist(app.app_url, session)
    if not isinstance(plist_data_raw, list) or not plist_data_raw:
        raise ValueError("Expected plist root to be a non-empty list")

    plist_data = plist_data_raw[0]
    title = plist_data.get("Title")
    if not title:
        raise ValueError("Title not found in plist")

    if not re.search(r'\d', title):
        version = plist_data["Update Version"]
    else:
        version = re.search(r"\d+(?:\.\d+)+", title).group()
    # print(version)

    if not version:
        raise ValueError("Could not determine version")

    if not app.download_url:
        download_url = plist_data["Location"]
        if not download_url:
            raise ValueError("Could not determine download URL")
    else:
        if "fwlink" in app.download_url:
            download_url = get_redirect_url(app.download_url, session)
        else:
            download_url = app.download_url

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_microsoft_edge(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    json_data = get_json(app.app_url, session)

    release_match = None
    for item in json_data:
        releases = item.get("Releases") or []

        for release in releases:
            if release.get("Platform") == "MacOS":
                release_match = release
                break

        if release_match:
            break

    if not release_match:
        raise ValueError("Could not find MacOS release")

    version = release_match.get("ProductVersion")
    if not version:
        raise ValueError("Could not determine version")

    artifacts = release_match.get("Artifacts") or []
    pkg_artifact = next(
        (
            artifact
            for artifact in artifacts
            if artifact.get("ArtifactName") == "pkg"
        ),
        None
    )

    if not pkg_artifact:
        raise ValueError("Could not find pkg artifact")

    download_url = pkg_artifact.get("Location")
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_logitune(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    json_data = get_json(app.app_url, session)

    bodies = [
        article["body"]
        for article in json_data.get("articles", [])
        if article.get("name") == "Logi Tune"
    ]

    soup = BeautifulSoup(bodies[0], "html.parser")

    span_tag = soup.find('span', string=lambda text: text and "Software Version:" in text)
    li_tag = span_tag.find_parent('li')
    version = li_tag.get_text(strip=True).replace("Software Version:", "").strip()

    for a_tag in soup.find_all('a', href=True):
        href = a_tag["href"]
        if ".dmg" in href:
            download_url = href
            break
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_affinity(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    version_string_text = soup.find(string=re.compile(r"Download version"))
    version_string_raw = str(version_string_text).strip()
    version = re.search(r"[\d.]+", version_string_raw).group()
    if not version:
        raise ValueError("Could not extract version")

    download_url = get_href_link(soup, ".dmg")
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_mysqlworkbench(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    h1_tag = soup.find(lambda tag: tag.name == "h1" and "MySQL Workbench" in tag.text.strip())
    version = re.sub(r"[^0-9.]", "", h1_tag.text)
    if not version:
        raise ValueError("Could not extract version")

    download_url_raw = get_href_link(soup, "-macos-arm64.dmg")
    download_url_tmp = download_url_raw.split('=')[1].split('&')[0]
    download_url = f"https://cdn.mysql.com//Downloads/MySQLGUITools/{download_url_tmp}"
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_charlesproxy(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    if not app.download_url_template:
        raise ValueError("download_url_template is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    strong_tag = soup.find("strong", string="Download a free trial")
    parent_tag = strong_tag.parent
    version_string_raw = parent_tag.get_text(strip=True)
    version = extract_version(version_string_raw)
    if not version:
        raise ValueError("Could not extract version")

    download_url = app.download_url_template.format(version=version)
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_isadora(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    target_div = soup.find('div', string=re.compile("Read the Isadora"))
    text = target_div.get_text(strip=True)
    version = extract_version(text)
    if not version:
        raise ValueError("Could not extract version")

    html = get_text(app.download_url, session)

    soup = BeautifulSoup(html, "html.parser")

    download_url_tmp = get_href_link(soup, "-std.dmg").lstrip("./")
    netloc = urlparse(app.download_url).netloc
    download_url = f"https://{netloc}/{download_url_tmp}"
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_labchart(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    h_tag = soup.find(name=lambda tag: tag.name == 'h1' and "LabChart" in tag.get_text())
    version_raw = h_tag.get_text(strip=True)
    version = extract_version(version_raw)
    if not version:
        raise ValueError("Could not extract version")

    download_url = get_href_link(soup, ".pkg")
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_googleearthpro(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    download_url = get_href_link(soup, "googleearthpromac")
    file_name = filename_from_url(download_url)
    version = extract_version(file_name)
    if not version:
        raise ValueError("Could not extract version")

    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_gpgtools(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    download_url = get_href_link(soup, ".dmg")
    file_name = filename_from_url(download_url)
    version = extract_version(file_name)
    if not version:
        raise ValueError("Could not extract version")

    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_python(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    download_url = get_href_link(soup, ".pkg")
    parts = download_url.split("/")
    version = parts[5]
    if not version:
        raise ValueError("Could not extract version")

    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_r(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    for a_tag in soup.find_all('a', string=re.compile('arm64.pkg')):
        download_url_raw = a_tag.get('href')
        version_raw = a_tag.text.strip()

    download_url = f"{app.app_url}/{download_url_raw}"

    version = version_raw.split("-")[1]
    if not version:
        raise ValueError("Could not extract version")

    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_openai(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    xml_data = get_xml(app.app_url, session)

    item = xml_data.find('./channel/item')
    enclosure = item.find('enclosure')
    version = item.find('title').text
    if not version:
        raise ValueError("Could not determine version")

    download_url = enclosure.get('url')
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_codex(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    xml_data = get_xml(app.app_url, session)

    item = xml_data.find('./channel/item')
    enclosure = item.find('enclosure')
    version = item.find('title').text
    if not version:
        raise ValueError("Could not determine version")

    download_url = enclosure.get('url')
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_imazingprofileeditor(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    xml_data = get_xml(app.app_url, session)

    item = xml_data.find('./channel/item')
    enclosure = item.find('enclosure')
    version = item.find('title').text
    if not version:
        raise ValueError("Could not determine version")

    download_url = enclosure.get('url')
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_itsycal(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    xml_data = get_xml(app.app_url, session)

    item = xml_data.find('./channel/item')
    enclosure = item.find('enclosure')
    version = item.find('title').text
    if not version:
        raise ValueError("Could not determine version")

    download_url = enclosure.get('url')
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_nitropdfpro(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    xml_data = get_xml(app.app_url, session)

    item = xml_data.find('./channel/item')
    enclosure = item.find('enclosure')

    app_title = item.find('title').text
    # version = re.search(r"\d+\.\d+\.\d+", app_title).group()
    version = extract_version(app_title)
    if not version:
        raise ValueError("Could not determine version")

    download_url = enclosure.get('url')
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_oraclejava8(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    xml_data = get_xml(app.app_url, session)

    download_url = xml_data.find('./mapping/url').text

    file_name = filename_from_url(download_url)
    version = extract_version(file_name).replace('_', '.')
    # version = version_str.replace('_', '.')
    if not version:
        raise ValueError("Could not determine version")

    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_catalystbrowse(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    json_data = get_json(app.app_url, session)

    version = json_data["lastVersion"]
    if not version:
        raise ValueError("Could not determine version")

    download_url = app.download_url
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_alfred(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    plist_data = get_plist(app.app_url, session)

    version = plist_data["version"]
    if not version:
        raise ValueError("Could not determine version")

    download_url = plist_data["location"]
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_claude(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    json_data = get_json(app.app_url, session)

    version = json_data["currentRelease"]
    if not version:
        raise ValueError("Could not determine version")

    download_url = json_data["releases"][0]["updateTo"]["url"]
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_druvainsync(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    json_data = get_json(app.app_url, session)

    macos_items = [
        item for item in json_data
        if isinstance(item, dict) and item.get("title") == "macOS"
    ]

    versions = macos_items[0]["supportedVersions"]
    versions.sort(reverse=True)
    version = versions[0]
    if not version:
        raise ValueError("Could not determine version")

    installer_details = macos_items[0]["installerDetails"]
    target_installer = next((
        installer for installer in installer_details
        if isinstance(installer, dict) and installer.get("version") == version
    ), None)

    download_url = target_installer.get("downloadURL")
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_elgatostreamdeck(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    json_data = get_json(app.app_url, session)

    version = json_data["sd-mac"]["version"]
    if not version:
        raise ValueError("Could not determine version")

    download_url = json_data["sd-mac"]["downloadURL"]
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_figma(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    json_data = get_json(app.app_url, session)

    version = json_data["version"]
    if not version:
        raise ValueError("Could not determine version")

    download_url = json_data["url"]
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_gemini(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    payload = {
        "request": {
            "@updater": "GoogleUpdater",
            "domainjoined": True,
            "protocol": "4.0",
            "os": {
                "platform": "MacOSX",
                "version": "26.0.0",
                "arch": "arm64"
            },
            "@os": "mac",
            "arch": "arm64",
            "acceptformat": "crx3,download,puff,run,xz,zucc",
            "apps": [
                {
                    "ap": "m1-prod",
                    "enabled": True,
                    "version": "1.00.0.000",
                    "updatecheck": {},
                    "appid": "com.google.GeminiMacOS"
                }
            ]
        }
    }

    response = session.post(
        app.app_url,
        json=payload,
        timeout=cfg.HTTP_TIMEOUT
    )
    response.raise_for_status()
    text = response.text
    if text.startswith(")]}'"):
        text = text.split("\n", 1)[1]

    json_data = json.loads(text)
    if json_data["response"]["apps"][0]["updatecheck"]["status"] != "ok":
        raise ValueError(
            "No update returned check returned"
        )

    version = json_data["response"]["apps"][0]["updatecheck"]["nextversion"]
    if not version:
        raise ValueError("Could not determine version")

    download_url = json_data["response"]["apps"][0]["updatecheck"]["pipelines"][0]["operations"][0]["urls"][2]["url"]
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_googlechrome(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    json_data = get_json(app.app_url, session)

    version = json_data["releases"][0]["version"]
    if not version:
        raise ValueError("Could not determine version")

    download_url = app.download_url
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_evernote(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    yaml_data = get_yaml(app.app_url, session)

    version = yaml_data["version"]
    if not version:
        raise ValueError("Could not find version")

    download_url = yaml_data["url"]
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_oktaverify(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    json_data = get_json(app.app_url, session)

    version = json_data["version"]
    if not version:
        raise ValueError("Could not determine version")

    download_url_raw = json_data["files"][0]["href"]
    domain = urlsplit(app.app_url).hostname
    download_url = f"https://{domain}{download_url_raw}"
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_plex(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    if not app.json_search_string:
        raise ValueError("json_search_string is required")

    json_data = get_json(app.app_url, session)

    version = json_data["computer"][app.json_search_string]["version"]
    if not version:
        raise ValueError("Could not determine version")

    download_url = json_data["computer"][app.json_search_string]["releases"][0]["url"]

    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_postman(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    json_data = get_json(app.app_url, session)

    version_maj = json_data["latestVersion"]
    version = json_data[version_maj][0]["version"]
    if not version:
        raise ValueError("Could not determine version")

    download_url = app.download_url
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_pycharm(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    json_data = get_json(app.app_url, session)

    version = json_data[0]["releases"][0]["version"]
    if not version:
        raise ValueError("Could not determine version")

    download_url = json_data[0]["releases"][0]["downloads"]["mac"]["link"]
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_raspberrypiimager(session: requests.Session, app: App) -> Result:
    if not app.download_url:
        raise ValueError("download_url is required")

    download_url = get_redirect_url(app.download_url, session)
    if not download_url:
        raise ValueError("Could not find download_url")

    # version = re.search(r"\d+\.\d+\.\d+", download_url).group()
    version = extract_version(download_url)
    if not version:
        raise ValueError("Could not find version")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_openvpnconnect(session: requests.Session, app: App) -> Result:
    if not app.download_url:
        raise ValueError("download_url is required")

    download_url = get_redirect_url(app.download_url, session)
    if not download_url:
        raise ValueError("Could not find download_url")

    version = re.search(r"\d+\.\d+\.\d+", download_url).group()
    if not version:
        raise ValueError("Could not find version")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_opera(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("download_url is required")

    link_one = get_redirect_url(app.app_url, session)

    html = get_text(link_one, session)

    soup = BeautifulSoup(html, "html.parser")

    tag = soup.find('a', {'data-event-action': 'thanks-download-link-default'})
    download_url_tmp = tag.get('href')
    download_url = get_redirect_url(download_url_tmp, session)
    if not download_url:
        raise ValueError("Could not find download_url")

    parts = download_url.split("/")
    version = parts[7]
    if not version:
        raise ValueError("Could not find version")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_githubdesktop(session: requests.Session, app: App) -> Result:
    if not app.download_url:
        raise ValueError("download_url is required")

    download_url = get_redirect_url(app.download_url, session)
    if not download_url:
        raise ValueError("Could not find download_url")

    version = extract_version(download_url)
    if not version:
        raise ValueError("Could not find version")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_sassafraskeyaccessmac(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    strong_tag = soup.find('strong', string=re.compile(r"Minor Version", re.IGNORECASE))
    if strong_tag:
        p_tag = strong_tag.find_parent('p')

    version = p_tag.get_text(strip=True).split(":")[-1].strip()
    if not version:
        raise ValueError("Could not determine version")

    download_url = get_href_link(soup, "ksp-client.pkg")
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_mafft(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(f"{app.app_url}/macstandard.html", session)

    soup = BeautifulSoup(html, "html.parser")

    download_url_raw = get_href_link(soup, "signed.pkg")
    download_url = f"{app.app_url}/{download_url_raw}"
    if not download_url:
        raise ValueError("Could not determine download URL")

    version = extract_version(download_url_raw)
    if not version:
        raise ValueError("Could not determine version")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_logioptionsplus(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    if not app.download_url:
        raise ValueError("download_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    meta_tag = soup.find('meta', content=re.compile("Version Release Date"))
    version = re.search(r"Version Release Date\s+(\d+\.\d+)", meta_tag['content']).group(1)
    if not version:
        raise ValueError("Could not determine version")

    download_url = app.download_url
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_makemkv(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(f"{app.app_url}/download/", session)

    soup = BeautifulSoup(html, "html.parser")

    for a_tag in soup.find_all('a', href=True):
        href = a_tag['href']
        if "osx.dmg" in href:
            download_url_raw = href
            version_raw = a_tag.text
            break

    download_url = f"{app.app_url}{download_url_raw}"
    if not download_url:
        raise ValueError("Could not determine download URL")

    version = extract_version(version_raw)
    if not version:
        raise ValueError("Could not determine version")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_displaylinkmanager(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(f"{app.app_url}/products/displaylink-graphics/downloads/macos", session)

    soup = BeautifulSoup(html, "html.parser")

    p_tag = soup.find(lambda tag: tag.name == "p" and "Release:" in tag.text)
    version_raw = p_tag.get_text(strip=True)
    version = re.search(r"Release:\s*([\d.]+)", version_raw).group(1)
    if not version:
        raise ValueError("Could not determine version")

    a_tag = soup.find('a', class_="release-notes-link")
    href = a_tag['href']
    parts = href.split("/")
    release_date = parts[5]
    download_url = f"{app.app_url}/sites/default/files/exe_files/{release_date}/DisplayLink%20Manager%20Graphics%20Connectivity{version}-EXE.pkg"
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_mestrenova(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(f"{app.app_url}/download", session)

    soup = BeautifulSoup(html, "html.parser")

    download_url_raw = get_href_link(soup, ".dmg")
    download_url = f"{app.app_url}{download_url_raw}"
    if not download_url:
        raise ValueError("Could not determine download URL")

    version = extract_version(download_url_raw)
    if not version:
        raise ValueError("Could not determine version")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_mp4joiner(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(f"{app.app_url}", session)

    soup = BeautifulSoup(html, "html.parser")

    tag = soup.find(string=re.compile("MacOSX.dmg")).parent
    version_raw = tag.get_text(strip=True)
    version = extract_version(version_raw)
    if not version:
        raise ValueError("Could not determine version")

    download_url = app.download_url_template.format(version=version)
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_parallels(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    x = 19
    while True:
        the_result = get_redirect_url(f"{app.app_url}{x}", session)
        if ".dmg" not in the_result:
            version_maj = x + 1
            break
        else:
            x = x - 1

    xml_data = get_xml(f"https://update.parallels.com/desktop/v{version_maj}/parallels/parallels_updates.xml", session)

    download_url = xml_data.findtext(".//Product/Version/Update/FilePath")

    parts = download_url.split("/")
    version_raw = parts[5]
    version = version_raw.split("-", 1)[0]

    if not version:
        raise ValueError("Could not determine version")

    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_sfsymbols(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    all_anchor_tags = soup.find_all('a', href=True)
    dmg_links = []
    for tag in all_anchor_tags:
        link = tag.get('href')
        if "dmg" in link:
            dmg_links.append(link.split('?')[0])

    dmg_links.sort()
    download_url = dmg_links[0]

    path = urlparse(dmg_links[0]).path
    file_name = filename_from_url(path)
    version = re.search(r"\d", file_name).group()
    if not version:
        raise ValueError("Could not determine version")

    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_endnote(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = subprocess.run(['curl', '-s', app.app_url], capture_output=True, text=True)
    soup = BeautifulSoup(html.stdout, "html.parser")

    h2_tag = soup.find_all(lambda tag: tag.name == 'h2' and 'macOS' in tag.get_text())
    clean_h2_tag = h2_tag[0].get_text(strip=True)
    version_words = clean_h2_tag.split()
    version_maj = version_words[1][:2]
    xml_data = get_xml(f"http://download.endnote.com/updates/{version_maj}.0/EN{version_maj}MacUpdates.xml", session)

    matches = xml_data.findall('.//updateTo')
    version = matches[-1].text
    if not version:
        raise ValueError("Could not determine version")

    download_url = app.download_url_template.format(version_maj=version_maj)
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_pymol(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)
    soup = BeautifulSoup(html, "html.parser")

    dmg_links = [
        a["href"]
        for a in soup.find_all("a", href=True)
        if "dmg" in a["href"].lower()
    ]

    if len(dmg_links) <= app.href_match_index:
        raise ValueError("Could not determine download URL")

    download_url = dmg_links[app.href_match_index]

    file_name = filename_from_url(download_url)
    version = extract_version(file_name)
    if not version:
        raise ValueError("Could not determine version")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_signal(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    yaml_data = get_yaml(app.app_url, session)

    version = yaml_data["version"]
    if not version:
        raise ValueError("Could not find version")

    download_url = app.download_url_template.format(version=version)
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_slack(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("download_url is required")

    download_url = get_redirect_url(app.app_url, session)
    if not download_url:
        raise ValueError("Could not find download_url")

    version = extract_version(download_url)
    if not version:
        raise ValueError("Could not find version")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_snagit(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    text = soup.find('meta', attrs={'name': 'description'})['content']
    version = re.search(r'\d{4}\.\d+(?:\.\d+)*', text).group(0)
    if not version:
        raise ValueError("Could not determine version")

    version_cleaned = version.replace(".", "")[2:]

    download_url = app.download_url_template.format(version=version_cleaned)
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_suspiciouspackage(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(f"{app.app_url}/SuspiciousPackage/update.html", session)

    soup = BeautifulSoup(html, "html.parser")

    text = soup.find('td', class_="version")
    version_raw = text.get_text(strip=True)
    version = extract_version(version_raw)
    if not version:
        raise ValueError("Could not determine version")

    text = soup.find('a', class_="download-link", href=True)
    download_url_raw = text.get('href')
    app_url_temp = app.app_url.replace("/software", "")
    download_url = f"{app_url_temp}{download_url_raw}"
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_coconutbattery(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    a_tag = soup.find(name=lambda tag: tag.name == 'a' and "Download v" in tag.get_text())
    version_raw = a_tag.get_text(strip=True)
    version = re.search(r"[\d.]+", version_raw).group()
    if not version:
        raise ValueError("Could not determine version")

    a_tags = soup.find_all('a', href=True)
    for a_tag in a_tags:
        link = a_tag.get('href')
        if ".zip" in link:
            download_url = link
            break
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_cycliqplus(session: requests.Session, app: App) -> Result:
    if not app.download_url:
        raise ValueError("download_url is required")

    download_url = get_redirect_url(app.download_url, session)
    if not download_url:
        raise ValueError("Could not determine download URL")

    file_name = filename_from_url(download_url)
    version = re.search(r"-(\d+(?:\.\d+)+)-", file_name).group(1)
    if not version:
        raise ValueError("Could not find version")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_dropbox(session: requests.Session, app: App) -> Result:
    if not app.download_url:
        raise ValueError("download_url is required")

    download_url = get_redirect_url(app.download_url, session)
    if not download_url:
        raise ValueError("Could not determine download URL")

    file_name = filename_from_url(download_url)
    version = extract_version(file_name)
    if not version:
        raise ValueError("Could not find version")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_intellijidea(session: requests.Session, app: App) -> Result:
    if not app.download_url:
        raise ValueError("download_url is required")

    download_url = get_redirect_url(app.download_url, session)

    if not download_url:
        raise ValueError("Could not determine download URL")

    file_name = filename_from_url(download_url)
    version = extract_version(file_name)
    if not version:
        raise ValueError("Could not find version")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_fetch(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(f"{app.app_url}/fetch/download", session)

    soup = BeautifulSoup(html, "html.parser")

    download_url_raw = get_href_link(soup, ".zip")
    download_url = f"{app.app_url}{download_url_raw}"

    file_name = filename_from_url(download_url)
    version = extract_version(file_name)
    if not version:
        raise ValueError("Could not find version")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_filemakerpro(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    json_data = get_json(app.app_url, session)

    matching_file = [
        item["file"] for item in json_data["listitem"] if re.compile(r'^PRO\d+MAC$').match(item["file"])
    ]
    matching_file.sort()
    version_maj = matching_file[-1]

    download_url = next(
        (item["url"] for item in json_data["listitem"] if item["file"] == version_maj),
        None
    )

    file_name = filename_from_url(download_url)
    version = re.search(r"(\d+\.\d+\.\d+\.)", file_name).group()
    if not version:
        raise ValueError("Could not determine version")

    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_freemind(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    tag = soup.find('p', string=lambda text: text and 'stable release' in text.lower())
    text = tag.get_text(strip=True)
    words = text.split()
    version = words[words.index("is") + 1].rstrip('.')
    if not version:
        raise ValueError("Could not find version")

    download_url = app.download_url_template.format(version=version)

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_gimp(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    p_tag = soup.find(lambda tag: tag.name == "p" and "The current stable release of GIMP is" in tag.get_text())
    version_raw = p_tag.get_text()
    version = extract_version(version_raw)
    if not version:
        raise ValueError("Could not find version")

    download_url_raw = get_href_link(soup, "arm64.dmg")
    download_url = f"https:{download_url_raw}"

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_pgadmin4(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    v_tags = [
        tag
        for tag in soup.find_all("a")
        if tag.get_text(strip=True).lower().startswith("v")
    ]
    last_v_tag = v_tags[-1] if v_tags else None
    version_raw = last_v_tag.get_text()
    version = re.sub(r'[^0-9.]', '', version_raw)
    if not version:
        raise ValueError("Could not find version")

    download_url = app.download_url_template.format(app.download_url_template, version=version)
    if not download_url:
        raise ValueError("Could not find download_url")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_sublime(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    if not app.download_url_template:
        raise ValueError("download_url is required")

    json_data = get_json(app.app_url, session)

    version = json_data['latest_version']
    if not version:
        raise ValueError("Could not determine version")

    download_url = app.download_url_template.format(version=version)

    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_pacifist(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    xml = get_xml(app.app_url, session)

    item_titles = xml.findall('.//item/title')
    last_title = item_titles[-1].text
    version = re.sub(r'[^0-9.]', '', last_title)
    if not version:
        raise ValueError("Could not determine version")

    items = xml.findall('.//item')
    last_item = items[-1]
    download_url_tmp = last_item.find('enclosure').get('url')
    download_url = get_redirect_url(download_url_tmp, session)
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_teamviewerqs(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)
    soup = BeautifulSoup(html, "html.parser")

    button = soup.find('custom-button', attrs={'text': 'Download for Mac'})
    target_div = button.find_parent('div', class_='cmp-smartdownloadbutton__wrapper')
    raw_json = target_div.get('data-json')
    parsed_data = json.loads(raw_json)

    version = parsed_data['data'][0]['versionNumber']
    if not version:
        raise ValueError("Could not determine version")

    download_url = parsed_data['data'][0]['downloadLink']
    if not download_url:
        raise ValueError("Could not determine download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_telegram(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    if not app.download_url:
        raise ValueError("download_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    h3_tag = soup.find("h3")
    version = h3_tag.contents[1].strip()

    download_url = app.download_url

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_theunarchiver(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    text = soup.find('div', class_="latest-version")
    version_raw = text.get_text(strip=True)
    version = extract_version(version_raw)
    download_url_raw = soup.select_one('a[href*="dmg"]')

    download_url = download_url_raw['href']

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_mozilla(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    if not app.download_url_template:
        raise ValueError("download_url_template is required")

    if not app.json_search_string:
        raise ValueError("json_search_string is required")
    json_data = get_json(app.app_url, session)

    version = json_data[app.json_search_string]
    if not version:
        raise ValueError("Could not find version")

    download_url = app.download_url_template.format(version=version)

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_touchdesigner(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    if not app.download_url_template:
        raise ValueError("download_url_template is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    version_raw = soup.find('span', class_="build-number")
    if not version_raw:
        raise ValueError("Could not find version")

    version = version_raw.get_text(strip=True)

    download_url = app.download_url_template.format(version=version)

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_visualstudiocode(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    json_data = get_json(app.app_url, session)

    version = json_data["productVersion"]
    if not version:
        raise ValueError("Could not find version")

    download_url = json_data["url"]
    if not download_url:
        raise ValueError("Could not find download_url")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_vlc(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    version_raw = soup.find('span', id="downloadVersion")
    version = version_raw.get_text(strip=True)
    if not version:
        raise ValueError("Could not find version")

    tag = soup.find('a', string="VLC for Mac (Universal Binary)")
    download_url_raw = tag.get('href')

    download_url = f"https:{download_url_raw}"

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_nvivo(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    span = soup.find("span", string="NVivo Mac")
    class_text = span.get("class")
    version_maj = re.search(r"NVivo_(\d+)_for_Mac", class_text[1]).group(1)
    download_url_tmp = app.download_url_template.format(version_maj=version_maj)

    download_url = get_redirect_url(download_url_tmp, session)
    full_version = download_url.split('/')[-2]
    version = '.'.join(full_version.split('.')[:3])

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_voodoopad(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    if not app.download_url_template:
        raise ValueError("download_url_template is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    text = soup.find('p', class_="latest-version")
    version_raw = text.get_text(strip=True)
    version = extract_version(version_raw)
    if not version:
        raise ValueError("Could not find version")

    download_url = app.download_url_template.format(version=version)

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_webex(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    if not app.download_url:
        raise ValueError("download_url is required")
    else:
        download_url = app.download_url

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    version_raw = soup.find('p', string=re.compile("Mac—"))
    version = version_raw.get_text(strip=True).removeprefix("Mac—").strip()
    if not version:
        raise ValueError("Could not find version")

    clean_session = requests.Session()
    clean_session.cookies.update(session.cookies)
    html = get_text(app.download_url, clean_session)

    soup = BeautifulSoup(html, "html.parser")

    for img in soup.find_all("img", class_="download-teams"):
        uri = img.get("uri")

        if uri and "silicon" in uri:
            download_url = uri
            break

    else:
        raise ValueError("Could not find Webex Apple silicon download URL")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_wireshark(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    xml = get_xml(app.app_url, session)

    version_raw = xml.find("channel/item/title").text
    version = extract_version(version_raw)
    if not version:
        raise ValueError("Could not find version")

    download_raw = xml.find("channel/item/enclosure")
    download_url = download_raw.get("url")
    if not download_url:
        raise ValueError("Could not find download_url")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_whatsapp(session: requests.Session, app: App) -> Result:
    if not app.download_url:
        raise ValueError("download_url is required")

    download_url = get_redirect_url_curl(app.download_url)
    base_url = download_url.split('?')[0]
    version = re.search(r'-2\.(\d+(?:\.\d+)*)\.dmg$', base_url).group(1)
    if not version:
        raise ValueError("Could not find version")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_yubicoauth(session: requests.Session, app: App) -> Result:
    if not app.download_url:
        raise ValueError("download_url is required")

    download_url = get_redirect_url(app.download_url, session)
    if not download_url:
        raise ValueError("Could not find download_url")

    version = re.search(r"\d+\.\d+\.\d+", download_url).group()
    if not version:
        raise ValueError("Could not find version")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_zotero(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    html = get_text(app.app_url, session)

    soup = BeautifulSoup(html, "html.parser")

    scripts = soup.find_all('script')
    for script in scripts:
        if script.string and 'standaloneVersions' in script.string:
            raw_data = script.string.split('=', 1)[1].strip().rstrip(';')
            json_string_raw = re.search(r'(\{.*\}).*?\)\);', raw_data, re.DOTALL).group(1)
            json_string = json.loads(json_string_raw)
            break

    version = json_string["standaloneVersions"]["mac"]
    if not version:
        raise ValueError("Could not find version")

    a_tag_href = soup.find('a', string="macOS")
    download_url_raw = a_tag_href['href']
    download_url = get_redirect_url(download_url_raw, session)
    if not download_url:
        raise ValueError("Could not find download_url")

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )


def scrape_zoom(session: requests.Session, app: App) -> Result:
    if not app.app_url:
        raise ValueError("app_url is required")

    if not app.download_url:
        raise ValueError("download_url is required")

    json_data = get_json(app.app_url, session)

    version_raw = json_data["result"]["downloadVO"]["zoom"]["displayVersion"]
    version = extract_version(version_raw)
    if not version:
        raise ValueError("Could not find version")

    download_url = app.download_url

    return Result(
        name=app.name,
        version=version,
        download_url=validate_download_url(download_url, session)
    )
