#!/usr/bin/env python3
import argparse
import subprocess
import sys

def get_git_refs(repo):
    """Fetches git refs directly from the remote repository url."""
    remote_url = f"https://github.com/{repo}.git"
    try:
        output = subprocess.check_output(["git", "ls-remote", remote_url], text=True)
    except subprocess.CalledProcessError as e:
        print(f"Error fetching git refs for {repo}: {e}", file=sys.stderr)
        sys.exit(1)

    refs = set()
    for line in output.splitlines():
        if "refs/badges/ci/" in line:
            # Extract the part after the namespace
            ref_suffix = line.split("refs/badges/ci/")[-1].strip()
            refs.add(ref_suffix)
    return refs

def parse_labels(filename):
    """Parses the labels file while preserving order."""
    ordered_refs = []
    labels = {}

    try:
        with open(filename, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                # Skip empty lines or lines without our delimiter
                if not line or ":" not in line:
                    continue

                ref, display_text = line.split(":", 1)
                ref = ref.strip()
                display_text = display_text.strip()

                # Keep the first occurrence for ordering in case of duplicates
                if ref not in labels:
                    ordered_refs.append(ref)
                labels[ref] = display_text
    except FileNotFoundError:
        print(f"Error: {filename} not found.", file=sys.stderr)
        sys.exit(1)

    return ordered_refs, labels

def generate_table_lines(repo, labels_file):
    """Generates the markdown lines for the status table."""
    available_refs = get_git_refs(repo)
    ordered_refs, labels = parse_labels(labels_file)

    rows = []

    # 1. Process matched refs in the exact order of the labels file
    for ref in ordered_refs:
        if ref in available_refs:
            display_text = labels[ref]

            # If display text is empty, skip emitting this row entirely
            if not display_text:
                available_refs.remove(ref)
                continue

            workflow = ref.split("/")[0]
            row = f"| {display_text} | [![Status](https://raw.githubusercontent.com/{repo}/refs/badges/ci/{ref}/status.svg)](https://github.com/{repo}/actions/workflows/{workflow}.yml) |"
            rows.append(row)
            available_refs.remove(ref)

    # 2. Process any remaining git refs not found in the labels file
    # Sort them deterministically (alphabetically)
    unmatched_refs = sorted(list(available_refs))
    for ref in unmatched_refs:
        workflow = ref.split("/")[0]
        row = f"| ??? | [![Status](https://raw.githubusercontent.com/{repo}/refs/badges/ci/{ref}/status.svg)](https://github.com/{repo}/actions/workflows/{workflow}.yml) |"
        rows.append(row)

    # 3. Assemble the generated markdown table lines
    table_lines = [
        "| Platform | Status |",
        "| -------- | ------|"
    ]
    table_lines.extend(rows)
    return table_lines

def update_readme(readme_path, table_lines):
    """Injects the generated table into the target markdown file between the fences."""
    try:
        with open(readme_path, "r", encoding="utf-8") as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: {readme_path} not found.", file=sys.stderr)
        sys.exit(1)

    start_marker = "<!-- DO NOT EDIT BELOW! AUTOSYNC CONTENT [STATUS TABLE] -->"
    end_marker = "<!-- DO NOT EDIT ABOVE! AUTOSYNC CONTENT [STATUS TABLE] -->"

    start_idx = content.find(start_marker)
    end_idx = content.find(end_marker)

    if start_idx == -1 or end_idx == -1:
        print(f"Note: could not find both AUTOSYNC fences in {readme_path}.", file=sys.stderr)
        return

    # slice up the file content and inject the new table
    before = content[:start_idx + len(start_marker)]
    after = content[end_idx:]

    new_content = before + "\n" + "\n".join(table_lines) + "\n" + after

    with open(readme_path, "w", encoding="utf-8") as f:
        f.write(new_content)

    print(f"Successfully updated status table in {readme_path}!")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate and inject a CI status badge table.")
    parser.add_argument("repo", help="Target GitHub repository (e.g., tayloraswift/swift-png)")
    parser.add_argument("--readme", default="README.md", help="Path to the target README file")
    parser.add_argument("--labels", default="StatusLabels.txt", help="Path to the labels text file")

    args = parser.parse_args()

    table_lines = generate_table_lines(args.repo, args.labels)
    update_readme(args.readme, table_lines)
