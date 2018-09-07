#!/usr/bin/env bash

set -e

red=$'\e[31m'
green=$'\e[32m'
blue=$'\e[34m'
magenta=$'\e[35m'
cyan=$'\e[36m'
reset=$'\e[0m'

MERGES=$(git log $(git merge-base --octopus $(git log -1 --merges --pretty=format:%P))..$(git log -1 --merges --pretty=format:%H) --pretty=format:%s)

SAVEDIFS=$IFS
IFS=$'\n'

MERGES=($MERGES)

IFS=$SAVEDIFS

LAST_COMMIT=$(git log -1 --pretty=format:%s)

TASKS=()

echo "${blue}⚡ ️Last commit:${cyan}"
echo $'\t'"📜 "$LAST_COMMIT
echo "${reset}"

if (( ${#MERGES[*]} > 0 ))
then
	echo "${blue}⚡ Last merge commits:${cyan}"

	for (( i=0 ; i<${#MERGES[*]} ; ++i ))
	do
		echo $'\t'"📜 "${MERGES[$i]}
	done

	echo "${reset}"

	if [ "$LAST_COMMIT" = "${MERGES[0]}" ];
	then
		echo "${green}✅ Merge commit detected. Searching for tasks in merge commits messages...${cyan}"
		for (( i=0 ; i<${#MERGES[*]} ; ++i ))
		do
			echo $'\t'"📜 "${MERGES[$i]}
		done

		for task in $(echo $MERGES | grep "$project_prefix[0-9]{1,5}" -E -o || true | sort -u -r --version-sort)
		do
			TASKS+=($task)
		done
	else
		echo "${magenta}☑️  Not a merge commit. Searching for tasks in current commit message...${cyan}"
		echo
		echo $'\t'"📜 "$LAST_COMMIT "${reset}"
		
		for task in $(echo $LAST_COMMIT | grep "$project_prefix[0-9]{1,5}" -E -o || true | sort -u -r --version-sort)
		do
			TASKS+=($task)
		done
	fi
fi

echo "${blue}✉️  Comment:${cyan}"
echo $'\t'"$jira_comment"

create_comment_data()
{
cat<<EOF
{
"body": "$jira_comment"
}
EOF
}

comment_data="$(create_comment_data)"

escaped_comment_data=$(echo ${comment_data} | sed -e "s#/#\\\/#g")

echo "${blue}⚡ Posting to:"
for (( i=0 ; i<${#TASKS[*]} ; ++i ))
do
	echo $'\t'"${magenta}⚙️  "${TASKS[$i]}
	
res="$(curl --write-out %{response_code} --silent --output /dev/null --user $jira_user:$jira_token --request POST --header "Content-Type: application/json" --data-binary "${escaped_comment_data}" --url https://${backlog_default_url}/rest/api/2/issue/${TASKS[$i]}/comment)"
	
	if test "$res" == "201"
	then
		echo $'\t'$'\t'"${green}✅ Success!${reset}"
	else
		echo $'\t'$'\t'"${red}❗️ Failed${reset}"
	fi
done
echo "${reset}"
