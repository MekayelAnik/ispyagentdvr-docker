#!/usr/bin/env python3
"""
Agent DVR Version Scraper
Scrapes the latest version information from iSpy Connect product history page.

Usage:
    python scrape_agentdvr_version.py                    # Get latest version as JSON
    python scrape_agentdvr_version.py --format github    # GitHub Actions output
    python scrape_agentdvr_version.py --count 5          # Get 5 most recent versions
    python scrape_agentdvr_version.py --since 6.5.0.0    # Get versions newer than 6.5.0.0
"""

import re
import json
import argparse
import sys
from datetime import datetime, timezone, timedelta
from typing import Optional

# Try requests first, fall back to urllib
try:
    import requests
    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False
    from urllib.request import urlopen, Request

from html.parser import HTMLParser


class VersionTableParser(HTMLParser):
    """Parse HTML table containing version history."""
    
    def __init__(self):
        super().__init__()
        self.in_table = False
        self.in_row = False
        self.in_cell = False
        self.in_th = False
        self.current_row = []
        self.rows = []
        self.cell_content = ""
        
    def handle_starttag(self, tag, attrs):
        if tag == "table":
            self.in_table = True
        elif tag == "tr" and self.in_table:
            self.in_row = True
            self.current_row = []
        elif tag == "td" and self.in_row:
            self.in_cell = True
            self.cell_content = ""
        elif tag == "th" and self.in_row:
            self.in_th = True
            
    def handle_endtag(self, tag):
        if tag == "table":
            self.in_table = False
        elif tag == "tr" and self.in_row:
            self.in_row = False
            if len(self.current_row) >= 3:
                self.rows.append(self.current_row)
        elif tag == "td" and self.in_cell:
            self.in_cell = False
            self.current_row.append(self.cell_content.strip())
        elif tag == "th":
            self.in_th = False
            
    def handle_data(self, data):
        if self.in_cell:
            self.cell_content += data


def fetch_page(url: str, timeout: int = 30) -> str:
    """Fetch HTML content from URL."""
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    }
    
    if HAS_REQUESTS:
        response = requests.get(url, headers=headers, timeout=timeout)
        response.raise_for_status()
        return response.text
    else:
        req = Request(url, headers=headers)
        with urlopen(req, timeout=timeout) as response:
            return response.read().decode("utf-8")


def parse_version_info(html: str) -> list[dict]:
    """Parse version information from HTML using multiple strategies."""
    versions = []
    
    # Strategy 1: Parse HTML table
    parser = VersionTableParser()
    parser.feed(html)
    
    for row in parser.rows:
        if len(row) >= 3:
            version = row[0].strip()
            if version.lower() == "version":
                continue
            if re.match(r"^\d+\.\d+\.\d+\.\d+$", version):
                versions.append({
                    "version": version,
                    "changes": row[1].strip(),
                    "date": row[2].strip()
                })
    
    # Strategy 2: Regex fallback if table parsing failed
    if not versions:
        pattern = r"(\d+\.\d+\.\d+\.\d+)\s*\|\s*([^|]+)\s*\|\s*(\d{1,2}/\d{1,2}/\d{4})"
        matches = re.findall(pattern, html)
        for match in matches:
            versions.append({
                "version": match[0].strip(),
                "changes": match[1].strip(),
                "date": match[2].strip()
            })
    
    return versions


def parse_date(date_str: str) -> datetime:
    """Parse date string in M/D/YYYY format."""
    try:
        return datetime.strptime(date_str, "%m/%d/%Y")
    except ValueError:
        try:
            return datetime.strptime(date_str, "%Y-%m-%d")
        except ValueError:
            return datetime.min


def get_versions_since(versions: list[dict], since_version: str) -> list[dict]:
    """Get all versions released after a specific version."""
    result = []
    sorted_versions = sorted(versions, key=lambda v: parse_date(v["date"]), reverse=True)
    
    for v in sorted_versions:
        if v["version"] == since_version:
            break
        result.append(v)
    
    return result


def is_version_stable(version: dict, stable_days: int = 5) -> bool:
    """
    Check if a version is stable.
    A version is considered stable if it has been the latest for at least `stable_days` days.
    """
    release_date = parse_date(version["date"])
    if release_date == datetime.min:
        return False
    
    today = datetime.now()
    days_since_release = (today - release_date).days
    return days_since_release >= stable_days


def get_stable_version(versions: list[dict], stable_days: int = 5) -> Optional[dict]:
    """
    Get the latest stable version.
    Returns the latest version that has been out for at least `stable_days` days.
    Returns None if no stable version exists.
    """
    sorted_versions = sorted(versions, key=lambda v: parse_date(v["date"]), reverse=True)
    
    for v in sorted_versions:
        if is_version_stable(v, stable_days):
            return v
    
    return None


def format_output(versions: list[dict], format_type: str, stable_days: int = 5, all_versions: list[dict] = None) -> str:
    """Format version data for output."""
    
    # Use all_versions for stable calculation if provided, otherwise use versions
    versions_for_stable = all_versions if all_versions else versions
    
    if not versions:
        if format_type == "github":
            return "new_version=false\nversion=\ndate=\nchanges=\nstable=false"
        elif format_type == "json":
            return json.dumps({"new_versions": False, "versions": []}, indent=2)
        return "No versions found"
    
    latest = versions[0]
    is_stable = is_version_stable(latest, stable_days)
    stable_version = get_stable_version(versions_for_stable, stable_days)
    
    # Calculate days since release
    release_date = parse_date(latest["date"])
    days_since = (datetime.now() - release_date).days if release_date != datetime.min else -1
    
    if format_type == "json":
        output = {
            "new_versions": True,
            "latest": {
                **latest,
                "stable": is_stable,
                "days_since_release": days_since
            },
            "versions": versions,
            "stable_version": stable_version,
            "stable_days_threshold": stable_days,
            "scraped_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
        }
        return json.dumps(output, indent=2)
    
    elif format_type == "env":
        return f"""AGENTDVR_VERSION={latest['version']}
AGENTDVR_DATE={latest['date']}
AGENTDVR_STABLE={str(is_stable).lower()}
AGENTDVR_DAYS_SINCE={days_since}
AGENTDVR_STABLE_VERSION={stable_version['version'] if stable_version else ''}
AGENTDVR_CHANGES={latest['changes'][:200]}"""
    
    elif format_type == "github":
        return f"""new_version=true
version={latest['version']}
date={latest['date']}
stable={str(is_stable).lower()}
days_since_release={days_since}
stable_version={stable_version['version'] if stable_version else ''}
changes<<CHANGES_EOF
{latest['changes']}
CHANGES_EOF"""
    
    elif format_type == "version":
        return latest['version']
    
    else:  # text
        lines = []
        for v in versions:
            v_stable = is_version_stable(v, stable_days)
            v_days = (datetime.now() - parse_date(v["date"])).days
            lines.extend([
                f"Version: {v['version']}" + (" [STABLE]" if v_stable else f" [{v_days} days old]"),
                f"Date: {v['date']}",
                f"Changes: {v['changes']}",
                "-" * 50
            ])
        return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Scrape Agent DVR version info")
    parser.add_argument("--url", default="https://www.ispyconnect.com/producthistory.aspx?productid=27")
    parser.add_argument("--format", "-f", choices=["json", "text", "env", "github", "version"], default="json")
    parser.add_argument("--since", "-s", help="Only show versions newer than this")
    parser.add_argument("--count", "-n", type=int, default=1)
    parser.add_argument("--stable-days", "-d", type=int, default=5,
                        help="Days a version must be latest to be considered stable (default: 5)")
    parser.add_argument("--stable-only", action="store_true",
                        help="Only return stable versions")
    parser.add_argument("--output", "-o", help="Output file")
    parser.add_argument("--input", "-i", help="Read from local HTML file")
    parser.add_argument("--quiet", "-q", action="store_true")
    
    args = parser.parse_args()
    
    try:
        html = open(args.input, "r").read() if args.input else fetch_page(args.url)
        versions = parse_version_info(html)
        
        if not versions:
            if not args.quiet:
                print("Error: No versions found", file=sys.stderr)
            sys.exit(1)
        
        if args.since:
            versions = get_versions_since(versions, args.since)
        
        sorted_versions = sorted(versions, key=lambda v: parse_date(v["date"]), reverse=True)
        
        # Filter to stable only if requested
        if args.stable_only:
            sorted_versions = [v for v in sorted_versions if is_version_stable(v, args.stable_days)]
            if not sorted_versions:
                if not args.quiet:
                    print(f"No stable versions found (threshold: {args.stable_days} days)", file=sys.stderr)
                # Output empty result in requested format
                result = format_output([], args.format, args.stable_days, all_versions=sorted_versions)
                if args.output:
                    open(args.output, "w").write(result)
                else:
                    print(result)
                return
        
        result = format_output(sorted_versions[:args.count], args.format, args.stable_days, all_versions=sorted_versions)
        
        if args.output:
            open(args.output, "w").write(result)
        else:
            print(result)
            
    except Exception as e:
        if not args.quiet:
            print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
