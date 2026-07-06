#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from __future__ import annotations

"""
appVers - a python appVers version scraper

Author: Mac Guy <https://github.com/gimmickyboot/macOS-App-Installers>
Licence: MIT
"""

__version__ = "1.0.0"


from typing import List

import argparse
import sys
import requests

from apps import apps
from helpers import send_email
from models import App, Result
import config as cfg


# set up cli args
parser = argparse.ArgumentParser(
    description="Application version scraper, "
                "with optional email sending. "
                "Refer to https://github.com/gimmickyboot/macOS-App-Installers"
)
parser.add_argument("-e", "--email",
                    action="store_true",
                    help="Send results as email."
                    )
parser.add_argument("-q", "--quiet",
                    action="store_true",
                    help="supress output to stdout"
                    )


# ---- runner ----
def run_all(apps: List[App], email: bool = False, quiet: bool = False) -> List[Result]:
    results: List[Result] = []

    with requests.Session() as session:
        session.headers.update({
            "User-Agent": cfg.USER_AGENT
        })

        for app in apps:
            try:
                res = app.scraper(session, app)
                results.append(res)
                if not quiet:
                    print(f"{res.name}: {res.version} -> {res.download_url}", flush=True,)

            except Exception as e:
                # In your real script, log the exception + continue
                print(f"[ERROR] {app.name}: {e}", file=sys.stderr)

    if email and results:
        send_email(results)

    return results


def main() -> int:
    args = parser.parse_args()

    run_all(apps, email=args.email, quiet=args.quiet)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
