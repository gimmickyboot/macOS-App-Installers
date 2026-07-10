from dataclasses import dataclass, field
from typing import Callable, Optional

import requests


@dataclass
class Result:
    name: str
    version: str
    download_url: str


@dataclass
class App:
    name: str
    scraper: Callable[[requests.Session, "App"], Result]
    app_url: Optional[str] = None
    download_url: Optional[str] = None
    download_url_template: Optional[str] = None
    sparkle_version_key: Optional[str] = None
    json_search_string: Optional[str] = None
    useragent: Optional[str] = None
    file_search_strings: list[str] = field(default_factory=list)
    href_match_index: int = 0
