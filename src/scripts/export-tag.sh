COMMIT_SHA=$(eval echo "$SHA")
echo "Commit hash: $COMMIT_SHA"
NAT='0|[1-9][0-9]*'
SEMVER_REGEX="\
^[vV]?\
($NAT)\\.($NAT)\\.($NAT)$"

PR_NUMBER=$(curl -s -X GET -u "$USER":"$GIT_USER_TOKEN" https://api.github.com/search/issues?q="$COMMIT_SHA" | jq .items[0].number)

LABEL=$(curl -s -X GET -u "$USER":"$GIT_USER_TOKEN" https://api.github.com/repos/mobomo/mbn-voltron/issues/"$PR_NUMBER"/labels  | jq .[0].name -r)

if [ "$LABEL" == null ] || [ "$LABEL" == "WIP" ]
then
    LABEL="patch"
fi

LAST_TAG=$(git describe --tags --abbrev=0 | sed -e "s/^'$PREFIX'//")

echo "Last Tag: $LAST_TAG"
echo "Semver part to update: $LABEL"

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
        local major=${BASH_REMATCH[1]}
        local minor=${BASH_REMATCH[2]}
        local patch=${BASH_REMATCH[3]}
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

    command=$LABEL
    version=$LAST_TAG

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

    echo "$new"
    echo "export NEW_SEMVER_TAG=${PREFIX}${new}" >> "$BASH_ENV"
    exit 0
}

increment