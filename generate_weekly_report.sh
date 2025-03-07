#!/bin/bash

if [ -z "$2" ]; then
  echo "Please supply a repo in the form of org/repo and an organization name (e.g. rancher)"
  exit 1
fi

SYSTEM=$(uname)
#check if MacOS or Linux because date is different
if [ "$SYSTEM" == "Darwin" ]; then
  WEEKAGO=$(date -v -90d +%F)
else
  WEEKAGO=$(date --date="last quarter" +%F)
fi
WEEK_NO=$(date +"%D")
TEMPLATE="{{range .}}* [#{{.number}}]({{.url}}):  {{.title}}{{\"\n\"}}{{end}}"
REPO_NAME=$1
ORG=$2
ORG_NAME="$(gh api -X GET "orgs/"$ORG"/members" -F per_page=100 --paginate --cache 1h --template='{{range .}}-author:{{.login}} {{end}}')"
read -r FORKS STARS < <(gh api -X GET "repos/"$REPO_NAME"" --template='{{.forks}} {{.stargazers_count}}')

FILENAME=".lastweek_${REPO_NAME//\//_}"
#echo $FILENAME

#check if we've already gotten the number of stars/forks from the previous week
if [ -f "$FILENAME" ]; then
  . $FILENAME
  #echo "Last month stats"
  #echo $LAST_WEEK_FORKS
  #echo $LAST_WEEK_STARS
  STAR_DIFF=$(expr $STARS - $LAST_WEEK_STARS)
  FORK_DIFF=$(expr $FORKS - $LAST_WEEK_FORKS)
  echo "LAST_WEEK_STARS=$STARS" > ./$FILENAME
  echo "LAST_WEEK_FORKS=$FORKS" >> ./$FILENAME
else
  echo "LAST_WEEK_STARS=$STARS" > ./$FILENAME
  echo "LAST_WEEK_FORKS=$FORKS" >> ./$FILENAME
fi

CLOSED_PR=$(gh pr list --limit 100 --repo $1 -S "closed:>$WEEKAGO" -s closed -t="$TEMPLATE" --json=title,milestone,url,number)
OPENED_PR=$(gh pr list --limit 100 --repo $1 -S "created:>$WEEKAGO" -s all -t="$TEMPLATE" --json=title,milestone,url,number)
CLOSED_ISSUES=$(gh issue list --limit 100 --repo $1 -S "closed:>$WEEKAGO" -s closed -t="$TEMPLATE" --json=title,milestone,url,number)
OPENED_ISSUES=$(gh issue list --limit 100 --repo $1 -S "created:>$WEEKAGO" -s all -t="$TEMPLATE" --json=title,milestone,url,number)
COMMUNITY_PR_CLOSED=$(gh pr list --limit 100 --repo $1 -S "closed:>$WEEKAGO $ORG_NAME" -s closed -t="$TEMPLATE" --json=title,milestone,url,number)
COMMUNITY_PR_OPEN=$(gh pr list --limit 100 --repo $1 -S "created:>$WEEKAGO $ORG_NAME" -s all -t="$TEMPLATE" --json=title,milestone,url,number)


none_or_print () {
  if [ -z "$1" ]; then
    echo "None"
  else
    echo "$1"
  fi
  echo ""
}

echo "# Monthy Report"
echo "Monthy status report for $REPO_NAME month #$WEEK_NO"
echo ""
echo ""
echo "## Here's what the team has focused on this Monthy:"
echo "* "

echo ""

echo "## Monthy Stats"
echo "| | Opened this month| Closed this month|"
echo "|--|---|-----|"
echo "|Issues| " $(wc -l <<< "$OPENED_ISSUES") "| "$(wc -l <<< "$CLOSED_ISSUES")"|"
echo "|PR's| " $(wc -l <<< "$OPENED_PR") "| " $(wc -l <<< "$CLOSED_PR")"|"

echo ""

echo "|  |  |"
echo "|--|--|"
echo "| New stars | "$STAR_DIFF"|"
echo "| New forks | "$FORK_DIFF"|"
echo ""


echo "## PR's Closed"
#closed PRs in the last month
none_or_print "$CLOSED_PR"

echo "## PR's Opened"
#opened PRSs last month
none_or_print "$OPENED_PR"

echo "## Issues Opened"
#opened issuess in the last month
none_or_print "$OPENED_ISSUES"

echo "## Issues Closed"
#closed issues in the last month
none_or_print "$CLOSED_ISSUES"

echo "## Community PRs Closed"
#Community PR's closed
none_or_print "$COMMUNITY_PR_CLOSED"

echo "## Community PRs Opened"
#Community PR's
none_or_print "$COMMUNITY_PR_OPEN"
