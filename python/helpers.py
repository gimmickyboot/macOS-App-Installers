from typing import Any
from email.message import EmailMessage
from urllib.parse import urlparse

import plistlib
import posixpath
import re
import smtplib
import subprocess
import xml.etree.ElementTree as ET

import requests
import yaml
from bs4 import BeautifulSoup

import config as cfg


def get_text(url: str, session: requests.Session, timeout: int = cfg.HTTP_TIMEOUT, headers: dict | None = None) -> str:
    r = session.get(url, timeout=timeout, allow_redirects=True, headers=headers)
    r.raise_for_status()
    return r.text


def get_json(url: str, session: requests.Session, timeout: int = cfg.HTTP_TIMEOUT) -> Any:
    r = session.get(url, timeout=timeout, allow_redirects=True)
    r.raise_for_status()
    return r.json()


def get_xml(url: str, session: requests.Session, timeout: int = cfg.HTTP_TIMEOUT) -> ET.Element:
    r = session.get(url, timeout=timeout, allow_redirects=True)
    r.raise_for_status()
    return ET.fromstring(r.content)


def get_plist(url: str, session: requests.Session, timeout: int = cfg.HTTP_TIMEOUT) -> Any:
    r = session.get(url, timeout=timeout, allow_redirects=True)
    r.raise_for_status()
    return plistlib.loads(r.content)


def get_yaml(url: str, session: requests.Session, timeout: int = cfg.HTTP_TIMEOUT) -> Any:
    r = session.get(url, timeout=timeout, allow_redirects=True,)
    r.raise_for_status()
    return yaml.safe_load(r.text)


def get_redirect_url(url: str, session: requests.Session, timeout: int = cfg.HTTP_TIMEOUT) -> str:
    response = session.head(url, timeout=timeout, allow_redirects=False)
    response.raise_for_status()

    redirect_url = response.headers.get("Location")
    if not redirect_url:
        raise ValueError("No redirect URL found")

    return requests.compat.urljoin(url, redirect_url)


def get_redirect_url_curl(url: str, timeout: int = cfg.HTTP_TIMEOUT) -> str:
    result = subprocess.run(
        ["curl", "-fsSI", "--max-time", str(cfg.HTTP_TIMEOUT), url],
        capture_output=True,
        text=True,
        check=True,
    )

    for line in result.stdout.splitlines():
        if line.lower().startswith("location:"):
            return line.split(":", 1)[1].strip()

    raise ValueError("No redirect URL found")


def get_href_link(soup: BeautifulSoup, search_str: str) -> str:
    for a_tag in soup.find_all('a', href=True):
        href = a_tag["href"]
        if search_str in href:
            return href

    raise ValueError(
        f"Could not find href containing '{search_str}'"
    )


def filename_from_url(url: str) -> str:
    return posixpath.basename(urlparse(url).path)


def extract_version(text: str, pattern: str = r"\d+(?:\.\d+)+") -> str:
    match = re.search(pattern, text)
    if not match:
        raise ValueError("Could not extract version")
    return match.group(1) if match.groups() else match.group()


def validate_download_url(
        url: str | None,
        session: requests.Session,
        timeout: int = cfg.HTTP_TIMEOUT,
) -> str:
    if not url:
        raise ValueError("Could not determine download URL")

    try:
        response = session.head(
            url,
            timeout=timeout,
            allow_redirects=True,
        )

        return url if response.ok else "ERROR"

    except requests.RequestException:
        return "ERROR"


# def send_email(results: list[Result]) -> None:
def send_email(body: str) -> None:
    # body = "\n".join(
    #     f"{r.name}: {r.version} -> {r.download_url}"
    #     for r in results
    # )

    msg = EmailMessage()
    msg["Subject"] = "AppVers email"
    msg["From"] = cfg.FROM_EMAIL
    msg["To"] = cfg.TO_EMAIL
    msg.set_content(body)

    with smtplib.SMTP(cfg.SMTP_SERVER, cfg.SMTP_PORT) as server:
        server.starttls()
        if cfg.EMAIL_USER and cfg.EMAIL_PASS:
            server.login(cfg.EMAIL_USER, cfg.EMAIL_PASS)
        server.send_message(msg)
