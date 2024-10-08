COMMIT_SHA=$(eval echo "$SHA")
echo "Commit hash: $COMMIT_SHA"
NAT='0|[1-9][0-9]*'
SEMVER_REGEX="\
(${PREFIX})?\
($NAT)\\.($NAT)\\.($NAT)$"

REPO_ORG="${CIRCLE_PROJECT_USERNAME}"
REPO_NAME="${CIRCLE_PROJECT_REPONAME}"

PR_NUMBER=$(curl -s -X GET -u "$USER":"$GIT_USER_TOKEN" https://api.github.com/search/issues?q="$COMMIT_SHA""+is:pull-request" | jq .items[0].number)

LABEL=$(curl -s -X GET -u "$USER":"$GIT_USER_TOKEN" https://api.github.com/repos/"$REPO_ORG"/"$REPO_NAME"/issues/"$PR_NUMBER"/labels | jq .[0].name -r)

if [ "$LABEL" == null ] || [ "$LABEL" == "WIP" ]; then
    LABEL="patch"
fi

echo "Try to get last tag using prefix: ${PREFIX}. If this is a new prefix, we will start from scratch."
# Since grep will return 1 if no match, we test for that and if matches will return 0 instead.
# Any other error code will exit as error (ie: 2). Circleci is running this with -eo pipefail,
# so we need to add the same test to all our greps :|
#LAST_TAG=$(git describe --tags --abbrev=0 | { grep -E "$PREFIX" || test $? = 1; } | { grep -v grep || test $? = 1; } | sed -e "s/^$PREFIX//")
LAST_TAG=$(git describe --tags --abbrev=0 --match "${PREFIX}*")

echo "Last Tag: $LAST_TAG"
echo "Semver part to update: $LABEL"

# Validate version format.
function validate_version {
    local version=$1
    echo "Version to validate: $version"
    if [[ "$version" =~ $SEMVER_REGEX ]]; then
      if [ "$#" -eq "2" ]; then
          local major=${BASH_REMATCH[2]}
          local minor=${BASH_REMATCH[3]}
          local patch=${BASH_REMATCH[4]}
          eval "$2=(\"$major\" \"$minor\" \"$patch\")"
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

    # If no last_tag was found, we start from scratch.
    if [ -z "$LAST_TAG" ]; then
        echo "LAST_TAG is empty, build tag name using prefix (${PREFIX})."
        LAST_TAG="${PREFIX}0.0.0"
        echo "New tag name built: ${LAST_TAG}".
    fi

    command=$LABEL
    version=$LAST_TAG

    echo "Validating tag name..."
    validate_version "$version" parts
    # shellcheck disable=SC2154
    local major="${parts[0]}"
    local minor="${parts[1]}"
    local patch="${parts[2]}"

    case "$command" in
    major) new="$((major + 1)).0.0";;
    minor) new="${major}.$((minor + 1)).0";;
    patch) new="${major}.${minor}.$((patch + 1))";;
    esac

    echo "New Tag: $new"
    NEW_SEMVER_TAG=${PREFIX}${new}
    echo "export NEW_SEMVER_TAG=$NEW_SEMVER_TAG" >> "$BASH_ENV"

    if [ -z "$NEW_SEMVER_TAG" ]; then
        echo "\$NEW_SEMVER_TAG is empty. Exiting!"
        exit 1
    else
        echo "\$NEW_SEMVER_TAG is: ${NEW_SEMVER_TAG}"
        exit 0
    fi
}

increment
