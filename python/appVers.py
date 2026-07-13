#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from __future__ import annotations

"""
appVers - a python appVers version scraper

Author: Mac Guy <https://github.com/gimmickyboot/macOS-App-Installers>
Licence: MIT
"""

__version__ = "1.0.2"


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
parser.add_argument(
    "-e",
    "--email",
    action="store_true",
    help="Send results as email."
)
parser.add_argument(
    "-q",
    "--quiet",
    action="store_true",
    help="supress output to stdout"
)
group = parser.add_mutually_exclusive_group()
group.add_argument(
    "-l",
    "--list",
    action="store_true",
    help="list all available apps"
)
group.add_argument(
    "-a",
    "--app",
    action="append",
    metavar="NAME",
    help="Run only the specified apps matching name(s). May be specified multiple times"
)


# ---- runner ----
def run_all(apps: List[App], email: bool = False, quiet: bool = False) -> List[Result]:
    configured_count = len(apps)
    attempted_count = 0
    success_count = 0
    failure_count = 0
    errors = []

    results: List[Result] = []

    with requests.Session() as session:
        session.headers.update({
            "User-Agent": cfg.USER_AGENT
        })

        for app in apps:
            attempted_count += 1

            try:
                res = app.scraper(session, app)
                results.append(res)
                success_count += 1

                if not quiet:
                    print(f"{res.name}: {res.version} -> {res.download_url}\n", flush=True,)

            except Exception as e:
                # In your real script, log the exception + continue
                failure_count += 1
                errors.append(f"{app.name}: {e}")
                print(f"[ERROR] {app.name}: {e}", file=sys.stderr, flush=True)

    summary = (
        f"Configured scrapers: {configured_count}\n"
        f"Attempted scrapers: {attempted_count}\n"
        f"Successful scrapers: {success_count}\n"
        f"Failed scrapers: {failure_count}\n"
    )

    if errors:
        summary += "\n\nFailures:\n"
        summary += "\n".join(errors)

    if email:
        # send_email(results)
        body = "\n".join(
            f"{r.name}: {r.version} -> {r.download_url}\n"
            for r in results
        )

        body += "\n\n" + summary
        send_email(body)

    if not quiet:
        print("\n" + summary, flush=True)

    return results


def main() -> int:
    args = parser.parse_args()

    selected_apps = apps
    if args.app:
        requested = {name.casefold() for name in args.app}
        selected_apps = [
            app
            for app in apps
            if app.name.casefold() in requested
        ]

        found = {app.name.casefold() for app in selected_apps}
        missing = requested - found

        if missing:
            print("The following app(s) weren't found:", file=sys.stderr)
            for name in sorted(missing):
                print(f"    {name}", file=sys.stderr)
            return 1

    if args.list:
        for app in sorted(apps, key=lambda app: app.name.casefold()):
            print(app.name)
        return 0

    run_all(selected_apps, email=args.email, quiet=args.quiet)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
