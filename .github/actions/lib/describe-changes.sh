#!/usr/bin/env bash
# Prints the non-merge commits in a revision range for a tag annotation, grouped by commit type: user-facing
# types (feat, fix, perf, vis) are listed, other types only counted. Subjects not of the form "<type>: ..." count
# as "uncategorised".
#
# Usage: describe-changes.sh <revision range>, e.g. describe-changes.sh prod/v2.1.0..HEAD
set -euo pipefail

git log --no-merges --format='%h %s' "$1" | awk -v max=50 '
    {
        sha = $1
        subject = substr($0, length(sha) + 2)
        type = "uncategorised"
        if (match(subject, /^[a-z]+(\([^)]*\))?!?: /)) {
            type = substr(subject, 1, RLENGTH)
            sub(/[(!:].*/, "", type)
            subject = substr(subject, RLENGTH + 1)
        }
        count[type]++
        if (count[type] <= max) lines[type] = lines[type] "- " subject " (" sha ")\n"
    }
    END {
        if (NR == 0) { print "No new commits"; exit }

        title["feat"] = "Features"; title["fix"] = "Fixes"; title["perf"] = "Performance"; title["vis"] = "Visual changes"
        n = split("feat fix perf vis", listed, " ")
        for (i = 1; i <= n; i++) {
            t = listed[i]
            if (!(t in count)) continue
            printf "%s:\n%s", title[t], lines[t]
            if (count[t] > max) printf "- … and %d more\n", count[t] - max
            delete count[t]
        }

        # Remaining types, most frequent first
        m = 0
        for (t in count) keys[++m] = t
        for (i = 1; i <= m; i++)
            for (j = i + 1; j <= m; j++)
                if (count[keys[j]] > count[keys[i]] || (count[keys[j]] == count[keys[i]] && keys[j] < keys[i])) {
                    t = keys[i]; keys[i] = keys[j]; keys[j] = t
                }
        other = ""
        for (i = 1; i <= m; i++) other = other (i > 1 ? ", " : "") count[keys[i]] " " keys[i]
        if (other != "") print "Other: " other
    }'
