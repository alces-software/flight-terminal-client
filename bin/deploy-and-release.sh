#!/bin/bash

set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)

main() {
    header "Checking repo is clean"
    abort_if_uncommitted_changes_present

    NEW_VERSION=$(get_new_version)
    header "Going to deploy, tag and push version ${NEW_VERSION}"
    wait_for_confirmation

    subheader "Creating release branch"
    checkout_release_branch
    subheader "Bumping version"
    bump_version
    commit_version_bump

    header "Running deploy script"
    run_deploy_script

    echo ""
    echo "${NEW_VERSION} has been deployed to staging app."
    echo "Test that all is good and then we'll promote staging to production"
    wait_for_confirmation
    promote_staging_to_production

    header "Migrating production database"
    migrate_production_database

    echo ""
    echo "Staging has been promoted to production."
    echo "Test that all is good and then we'll continue with tag creation and pushing"
    wait_for_confirmation

    header "Merging, tagging, and pushing"
    run_merge_script
}

abort_if_uncommitted_changes_present() {
    if ! git diff-index --quiet HEAD ; then
        echo "$0: Uncommitted changes present aborting. Either stash or commit."
        exit 2
    fi
}

get_new_version() {
    "${REPO_ROOT}"/bin/bump_version.rb "${REPO_ROOT}"/version.json --dry-run \
        | jq -r '(.major|tostring) + "." + (.minor|tostring)'
}

bump_version() {
    "${REPO_ROOT}"/bin/bump_version.rb "${REPO_ROOT}"/version.json
}

checkout_release_branch() {
    git checkout -b release/"${NEW_VERSION}"
}

commit_version_bump() {
    cp -f "${REPO_ROOT}/version.json" "${REPO_ROOT}/client/src/data/version.json"
    cp -f "${REPO_ROOT}/version.json" "${REPO_ROOT}/server/lib/launch/version.json"
    git commit -m "Bump version to ${NEW_VERSION}" \
        "${REPO_ROOT}/version.json" \
        "${REPO_ROOT}/client/src/data/version.json" \
        "${REPO_ROOT}/server/lib/launch/version.json"
}

run_deploy_script() {
    "${REPO_ROOT}"/bin/deploy.sh
}

promote_staging_to_production() {
    local dokku_server
    local staging_app
    local production_app
    dokku_server=$( git remote get-url dokku-staging | cut -d@ -f2 | cut -d: -f1 )
    staging_app=$( git remote get-url dokku-staging | cut -d: -f2 )
    production_app=$( git remote get-url dokku | cut -d: -f2 )

    ssh ${dokku_server} \
        "sudo docker tag dokku/${staging_app} dokku/${production_app} ; dokku tags:deploy ${production_app} latest"
}

migrate_production_database() {
    local dokku_server
    local production_app
    dokku_server=$( git remote get-url dokku-staging | cut -d@ -f2 | cut -d: -f1 )
    production_app=$( git remote get-url dokku | cut -d: -f2 )

    ssh ${dokku_server} \
        "dokku run \"${production_app}\" rake db:migrate:status; dokku run \"${production_app}\" rake db:migrate"
}

run_merge_script() {
    "${REPO_ROOT}"/bin/merge-and-tag-release.sh "${NEW_VERSION}"

}

wait_for_confirmation() {
    echo ""
    echo "Press enter to continue or Ctrl-C to abort like a coward"
    read -s
}

header() {
    echo -e "=====> $@"
}

subheader() {
    echo -e "-----> $@"
}

indent() {
    sed 's/^/       /'
}

main "$@"
