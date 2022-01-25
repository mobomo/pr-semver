COMMIT_SHA=$(eval echo "$SHA")
echo "Commit hash: $COMMIT_SHA"

# valid semvar for consideration must contain a "v" prefix and no postfix
NAT='0|[1-9][0-9]*'
SEMVER_REGEX="\
^([vV])\
($NAT)\\.($NAT)\\.($NAT)$"

REPO_NAME="${CIRCLE_PROJECT_REPONAME}"

# choose the first/most recent PR that this commit is part of - might have issues picking between multiple prs
PR_NUMBER=$(curl -s -X GET -H "Authorization: token $GIT_USER_TOKEN" https://api.github.com/search/issues?q="$COMMIT_SHA" | jq .items[0].number)

# select all the labels of this PR
LABELS=$(curl -s -X GET -H "Authorization: token $GIT_USER_TOKEN" https://api.github.com/repos/"$REPO_NAME"/issues/"$PR_NUMBER"/labels | jq .[].name -r)

# to ensure uniqueness, find the highest semvar of any tag in the repo
LARGEST_TAG=$(git tag | grep -E $SEMVER_REGEX | sort -r --version-sort | head -n1)

echo "Largest Tag: $LARGEST_TAG"
echo "Labels: $LABELS"

# Show error message.
function error {
    echo -e "$1" >&2
    exit 1
}

# Validate version format.
function validate_version {
    local version=$1
    echo "$version"
    if [[ "$version" =~ $SEMVER_REGEX ]]; then
    if [ "$#" -eq "2" ]; then
        local prefix=${BASH_REMATCH[1]}
        local major=${BASH_REMATCH[2]}
        local minor=${BASH_REMATCH[3]}
        local patch=${BASH_REMATCH[4]}
        eval "$2=(\"$prefix\" \"$major\" \"$minor\" \"$patch\")"
    else
        echo "$version"
    fi
    else
    error "version $version does not match the semver scheme 'X.Y.Z'. See help for more information."
    fi
}

# Increment.
function increment {
    local new; local version; local command;

    commands=$LABELS

    # no labels count as "patch"
    if [ "$commands" == null ] || [ -z "$commnands" ]; then
        commands="patch"
    fi

    version=$LARGEST_TAG

    validate_version "$version" parts

    # shellcheck disable=SC2154
    local prefix="${parts[0]}"
    local major="${parts[1]}"
    local minor="${parts[2]}"
    local patch="${parts[3]}"

    local has_major=0;
    local has_minor=0;
    local has_patch=0;
    local new="$version"

    for command in $commands; do
        lcommand=$(echo "$command" | tr '[:upper:]' '[:lower:]')
        echo "Checking '$lcommand'"
        if [ "$lcommand" = "major" ]; then
            new="$((major + 1)).0.0"
            has_major=1
        elif [ "$lcommand" = "minor" ] && [ $has_major -eq 0 ]; then
            new="${major}.$((minor + 1)).0"
            has_minor=1
        elif [ "$lcommand" = "patch" ] && [ $has_major -eq 0 ] && [ $has_minor -eq 0 ]; then
            new="${major}.${minor}.$((patch + 1))"
            has_patch=1
        elif [ "$lcommand" = "wip" ] && [ $has_major -eq 0 ] && [ $has_minor -eq 0 ]; then
            new="${major}.${minor}.$((patch + 1))"
            has_patch=1
        fi
    done

    echo "$new"
    echo "export NEW_SEMVER_TAG=${prefix}${new}" >> "$BASH_ENV"

    if [ -z "$NEW_SEMVER_TAG" ]
    then
          echo "\$NEW_SEMVER_TAG is empty. Exiting!"
          exit 1
    else
          echo "\$NEW_SEMVER_TAG is: ${NEW_SEMVER_TAG}"
          exit 0
    fi
}

increment