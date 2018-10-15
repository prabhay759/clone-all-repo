#!/usr/bin/env bash
BRANCH_NAME="" # SO-123AddedConfigFiles
NAMESPACE="" # Carriers
BASE_PATH="" # https://abc.githost.io/
PROJECT_SEARCH_PARAM=""
PROJECT_SELECTION="select(.namespace.name == \"$NAMESPACE\")"
PROJECT_PROJECTION="{ "path": .path, "git": .ssh_url_to_repo }"

if [ -z "$GITLAB_API_KEY" ]; then
    echo "Please set the environment variable GITLAB_API_KEY"
    echo "See ${BASE_PATH}profile/account"
    exit 1
fi

FILENAME="repos.json"

trap "{ rm -f $FILENAME; }" EXIT
echo "Cloning repos"
curl -X GET \
  https://cimpress.githost.io/api/v4/groups/191/projects \
  -H 'private-token: 4KKytzjGgUwNTe1VLzKK' \
  | jq --raw-output --compact-output ".[] | $PROJECT_SELECTION | $PROJECT_PROJECTION" > "$FILENAME"
while read repo; do
    THEPATH=$(echo "$repo" | jq -r ".path")
    GIT=$(echo "$repo" | jq -r ".git")
    
    if [ ! -d "$THEPATH" ]; then
        echo "Cloning $THEPATH ( $GIT )"
        git clone "$GIT" --quiet && cd "$THEPATH" && git checkout -b "$BRANCH_NAME" && npm install &
    else
        echo "Pulling $THEPATH"
        (cd "$THEPATH" && git reset --hard && git checkout master && git pull --quiet && git checkout -b "SO-442OmitingAuthTokenFromLogging") && npm install &
    fi
done < "$FILENAME"

wait
read -p "Press [Enter] key to start backup..."
