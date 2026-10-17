#!/usr/bin/env python3
"""Fetch recent photos from the Instagram API into _data/photos.json.

Reads IG_ACCESS_TOKEN from the environment. The token never reaches the
browser: Jekyll renders the list into the page at build time. Instagram CDN
URLs expire after a few days, so the workflow rebuilds daily.
"""
import json
import os
import sys
import urllib.parse
import urllib.request

API = "https://graph.instagram.com"
OUT = os.path.join(os.path.dirname(__file__), "..", "_data", "photos.json")
FIELDS = "id,caption,media_type,media_url,permalink,timestamp,children{media_type,media_url}"
LIMIT = 100


def get(url):
    try:
        with urllib.request.urlopen(url, timeout=30) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        # Instagram's error body explains the cause and never echoes the token
        sys.exit(f"Instagram API error {e.code}: {e.read().decode()[:400]}")


def refresh(token):
    # Keeps the long-lived token (60-day expiry) alive; failure is not fatal.
    q = urllib.parse.urlencode({"grant_type": "ig_refresh_token", "access_token": token})
    try:
        get(f"{API}/refresh_access_token?{q}")
    except SystemExit as e:
        print(f"warning: token refresh failed: {e}", file=sys.stderr)


def photos(token):
    q = urllib.parse.urlencode({"fields": FIELDS, "limit": 50, "access_token": token})
    url, out = f"{API}/me/media?{q}", []
    while url and len(out) < LIMIT:
        page = get(url)
        for m in page.get("data", []):
            if m["media_type"] == "CAROUSEL_ALBUM":
                kids = m.get("children", {}).get("data", [])
                srcs = [c["media_url"] for c in kids if c["media_type"] == "IMAGE" and c.get("media_url")]
            elif m["media_type"] == "IMAGE" and m.get("media_url"):
                srcs = [m["media_url"]]
            else:
                continue
            for src in srcs:
                out.append({"src": src, "caption": (m.get("caption") or "").strip(),
                            "link": m["permalink"], "date": m["timestamp"][:10]})
        url = page.get("paging", {}).get("next")
    return out[:LIMIT]


def main():
    token = os.environ.get("IG_ACCESS_TOKEN")
    if not token:
        sys.exit("IG_ACCESS_TOKEN not set")
    refresh(token)
    items = photos(token)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w") as f:
        json.dump(items, f, indent=1)
    print(f"wrote {len(items)} photos")


if __name__ == "__main__":
    main()
