#!/usr/bin/env bash

#
# SwiftChessTools provides reusable chess rules, notation, UCI helpers, and SwiftUI board UI.
#
# See NOTICE.md for upstream attribution and license details.
#
# Licensed under the MIT License.
# You may obtain a copy of the License at: https://opensource.org/licenses/MIT
# See the LICENSE file for more information.
#

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
cd "$repo_root"

workflow_file="ci.yml"
requested_ref=""

usage() {
  cat <<'EOF'
Usage: Scripts/run-github-ci.sh [ref]
       Scripts/run-github-ci.sh --ref <ref>

Dispatch the optional GitHub Actions CI workflow for a branch or tag that
already exists on GitHub. Without a ref, use the current branch, or the
repository's default branch when HEAD is detached.

This script never commits or pushes local changes.
EOF
}

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

while (($# > 0)); do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --ref)
      (($# >= 2)) || fail "--ref requires a branch or tag."
      [[ -z "$requested_ref" ]] || fail "Specify only one ref."
      requested_ref="$2"
      shift 2
      ;;
    -*)
      fail "Unknown option: $1"
      ;;
    *)
      [[ -z "$requested_ref" ]] || fail "Specify only one ref."
      requested_ref="$1"
      shift
      ;;
  esac
done

command -v git >/dev/null 2>&1 || fail "git is required."
command -v gh >/dev/null 2>&1 || fail "GitHub CLI is required. Install it and run 'gh auth login'."

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "Run this script from a Git checkout."

if ! gh auth status --hostname github.com >/dev/null 2>&1; then
  fail "GitHub CLI is not authenticated for github.com. Run 'gh auth login'."
fi

if ! repository="$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null)" || [[ -z "$repository" ]]; then
  fail "Could not resolve the GitHub repository from this checkout."
fi

current_branch="$(git branch --show-current)"
ref="$requested_ref"
if [[ -z "$ref" ]]; then
  ref="$current_branch"
fi
if [[ -z "$ref" ]]; then
  if ! ref="$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name' 2>/dev/null)" || [[ -z "$ref" ]]; then
    fail "Could not determine a ref. Pass one explicitly with --ref."
  fi
fi

if ! workflow_state="$(gh api "repos/$repository/actions/workflows/$workflow_file" --jq '.state' 2>/dev/null)"; then
  fail "The $workflow_file workflow is not available on GitHub's default branch."
fi
if [[ "$workflow_state" != "active" ]]; then
  fail "The $workflow_file workflow is $workflow_state on GitHub; enable it before dispatching."
fi

if ! workflow_yaml="$(
  gh workflow view "$workflow_file" --repo "$repository" --ref "$ref" --yaml 2>/dev/null
)"; then
  fail "Ref '$ref' does not exist on GitHub or does not contain .github/workflows/$workflow_file."
fi
if ! grep -Eq '^[[:space:]]+workflow_dispatch:[[:space:]]*($|#)' <<<"$workflow_yaml"; then
  fail "The $workflow_file workflow at '$ref' is not configured for manual dispatch."
fi

if [[ -n "$(git status --porcelain)" ]]; then
  printf '%s\n' \
    "Warning: local uncommitted changes are not included in this run." \
    "The dispatch will use the files already present on GitHub at '$ref'." \
    "This script will not commit or push those changes." >&2
fi
if [[ -n "$current_branch" && "$current_branch" == "$ref" ]]; then
  if remote_sha="$(
    git ls-remote --exit-code origin "refs/heads/$ref" 2>/dev/null |
      awk 'NR == 1 { print $1 }'
  )" && [[ -n "$remote_sha" ]]; then
    local_sha="$(git rev-parse HEAD)"
    if [[ "$local_sha" != "$remote_sha" ]]; then
      printf 'Warning: local HEAD %s differs from origin/%s at %s.\n' \
        "$local_sha" "$ref" "$remote_sha" >&2
      printf '%s\n' \
        "The workflow will run the remote commit; this helper will not push local commits." >&2
    fi
  else
    printf 'Warning: could not compare local HEAD with origin/%s.\n' "$ref" >&2
  fi
fi

if ! known_run_ids="$(gh run list \
  --repo "$repository" \
  --workflow "$workflow_file" \
  --event workflow_dispatch \
  --limit 100 \
  --json databaseId \
  --jq '.[].databaseId')"; then
  fail "Could not read existing workflow runs."
fi

printf 'Repository: %s\nWorkflow:   %s\nRef:        %s\n' \
  "$repository" "$workflow_file" "$ref"
printf 'Dispatching the workflow already stored on GitHub; no commit or push will occur.\n\n'

gh workflow run "$workflow_file" --repo "$repository" --ref "$ref"

run_record=""
for ((attempt = 1; attempt <= 10; attempt++)); do
  runs="$(gh run list \
    --repo "$repository" \
    --workflow "$workflow_file" \
    --event workflow_dispatch \
    --branch "$ref" \
    --limit 20 \
    --json databaseId,url,status,createdAt,headBranch,headSha \
    --jq '.[] | [.databaseId, .url, .status, .createdAt, .headBranch, .headSha] | @tsv' \
    2>/dev/null || true)"

  while IFS=$'\t' read -r run_id run_url run_status created_at head_branch head_sha; do
    [[ -n "$run_id" ]] || continue
    if ! grep -Fxq "$run_id" <<<"$known_run_ids"; then
      run_record="$run_id"$'\t'"$run_url"$'\t'"$run_status"$'\t'"$created_at"$'\t'"$head_branch"$'\t'"$head_sha"
      break
    fi
  done <<<"$runs"

  [[ -z "$run_record" ]] || break
  sleep 2
done

if [[ -n "$run_record" ]]; then
  IFS=$'\t' read -r run_id run_url run_status created_at head_branch head_sha <<<"$run_record"
  printf '\nRun created:\n'
  printf '  URL:      %s\n' "$run_url"
  printf '  Run ID:   %s\n' "$run_id"
  printf '  Status:   %s\n' "$run_status"
  printf '  Created:  %s\n' "$created_at"
  printf '  Ref:      %s\n' "$head_branch"
  printf '  Head SHA: %s\n' "$head_sha"
  printf '\nWatch when desired:\n  gh run watch %s --repo %s\n' "$run_id" "$repository"
else
  printf '\nThe dispatch was accepted, but the new run is not listed yet.\n'
  printf 'View workflow runs at: https://github.com/%s/actions/workflows/%s\n' \
    "$repository" "$workflow_file"
fi
