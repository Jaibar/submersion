"""Resolve upstream-merge conflicts that are only in the localization files.

Called by private-sync.yml in the middle of a conflicted `git merge
upstream/main`. Both sides append new keys at the end of every lib/l10n/arb
app_xx.arb, so a merge always conflicts there once this branch has added its
own strings (the what-if ones).

Rule, per ARB file: take upstream's file whole, then re-add the keys this
branch added itself (in HEAD, not in the merge base, not in upstream).
Generated app_localizations*.dart files are taken from upstream; the test
build regenerates them with `flutter gen-l10n` and commits the result.

Exit 0 when every conflicted file was a localization file and is now resolved;
exit 1 (nothing touched) when any other file conflicts, so the merge is aborted
as before and a person looks at it.
"""
import glob
import json
import re
import subprocess
import sys
from collections import OrderedDict


def git(*args):
    return subprocess.run(["git", *args], capture_output=True, check=True).stdout.decode("utf-8")


def show(ref, path):
    return git("show", f"{ref}:{path}")


conflicted = git("diff", "--name-only", "--diff-filter=U").split()
ARB = re.compile(r"^lib/l10n/arb/app_[a-z]{2}\.arb$")
GEN = re.compile(r"^lib/l10n/arb/app_localizations.*\.dart$")
others = [f for f in conflicted if not (ARB.match(f) or GEN.match(f))]
if others:
    print("Non-localization conflicts, not resolving:", *others, sep="\n  ")
    sys.exit(1)

base_ref = git("merge-base", "HEAD", "upstream/main").strip()
for path in sorted(glob.glob("lib/l10n/arb/app_??.arb")):
    path = path.replace("\\", "/")
    up = json.loads(show("upstream/main", path), object_pairs_hook=OrderedDict)
    mine = json.loads(show("HEAD", path), object_pairs_hook=OrderedDict)
    base = json.loads(show(base_ref, path), object_pairs_hook=OrderedDict)
    added = [k for k in mine if k not in base and k not in up]
    for k in added:
        up[k] = mine[k]
    with open(path, "w", encoding="utf-8", newline="") as f:
        f.write(json.dumps(up, ensure_ascii=False, indent=2) + "\n")
    print(f"{path}: kept {len(added)} branch-only keys")

for path in glob.glob("lib/l10n/arb/app_localizations*.dart"):
    git("checkout", "upstream/main", "--", path.replace("\\", "/"))
git("add", "lib/l10n")
print("Localization conflicts resolved.")
