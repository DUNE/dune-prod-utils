#!/usr/bin/env python3
"""
Query MetaCat for files matching specified criteria and generate per-run queries.

This script:
1. Uses the MetaCat Python API to query files matching the given MQL query
2. Extracts unique run numbers from the file metadata
3. Prints a query for each unique run number
"""

import argparse
import os
import sys
from collections import defaultdict

from metacat.webapi import MetaCatClient


def extract_run_numbers(files: list[dict]) -> dict[int, int]:
    """Extract unique run numbers from file metadata and count files per run."""
    run_counts = defaultdict(int)
    
    for f in files:
        metadata = f.get('metadata', {})
        # Try different possible locations for run number
        run_number = (
            metadata.get('core.run_number') or
            (metadata.get('core.runs', [None])[0] if metadata.get('core.runs') else None)
        )
        
        if run_number is not None:
            run_counts[int(run_number)] += 1
        else:
            name = f.get('name', 'unknown')
            namespace = f.get('namespace', '')
            print(f"Warning: No run number found for file {namespace}:{name}", file=sys.stderr)
    
    return dict(run_counts)


def generate_run_query(run_number: int) -> str:
    """Generate a MetaCat query for a specific run number."""
    return f"files where core.run_number={run_number}"


def main():
    parser = argparse.ArgumentParser(
        description="Query MetaCat and generate per-run queries"
    )
    parser.add_argument(
        "query",
        help="MQL query string"
    )
    
    args = parser.parse_args()
    
    client = MetaCatClient('https://metacat.fnal.gov:9443/dune_meta_prod/app')
    
    # Execute the query with metadata
    print(f"Query: {args.query}\n")
    print("Querying MetaCat...")
    try:
        files = list(client.query(args.query, with_metadata=True))
    except Exception as e:
        print(f"Error executing MetaCat query: {e}", file=sys.stderr)
        sys.exit(1)
    
    print(f"Found {len(files)} files\n")
    
    if not files:
        print("No files found matching the query.")
        return
    
    # Extract unique run numbers
    run_counts = extract_run_numbers(files)
    
    if not run_counts:
        print("No run numbers found in file metadata.")
        return
    
    # Sort run numbers
    sorted_runs = sorted(run_counts.keys())
    
    print(f"Found {len(sorted_runs)} unique run number(s):\n")
    print("-" * 80)
    
    # Print summary
    for run_number in sorted_runs:
        print(f"Run {run_number}: {run_counts[run_number]} file(s)")
    
    print("-" * 80)
    print("\nPer-run queries:\n")
    
    # Generate and print queries for each run
    for run_number in sorted_runs:
        query = generate_run_query(run_number)
        print(f"# Run {run_number} ({run_counts[run_number]} files)")
        print(query)
        print()


if __name__ == "__main__":
    main()
