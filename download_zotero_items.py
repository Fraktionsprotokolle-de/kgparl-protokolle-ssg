#!/usr/bin/env python3
"""
Script to automatically download all Zotero items using configuration from zotero-config.xml
"""

import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path
import os

def read_config(config_path='zotero-config.xml'):
    """Read the Zotero configuration from XML file."""
    if not os.path.exists(config_path):
        print(f"Error: Configuration file '{config_path}' not found.")
        sys.exit(1)

    with open(config_path, 'r') as file:
        xml_text = file.read()

    root = ET.fromstring(xml_text)

    config = {
        'groupid': root.find('groupid').text,
        'last_modified_version': root.find('last-modified-version').text,
        'format': root.find('format').text,
        'data_dir': root.find('data-dir').text,
    }

    return config

def update_config(config_path, last_modified_version):
    """Update the last-modified-version in the config file."""
    tree = ET.parse(config_path)
    root = tree.getroot()

    version_element = root.find('last-modified-version')
    if version_element is not None:
        version_element.text = str(last_modified_version)
        tree.write(config_path, encoding='unicode', xml_declaration=False)
        print(f"Updated config file with last-modified-version: {last_modified_version}")

def main():
    """Main function to download Zotero items."""
    config_path = 'zotero-config.xml'

    # Read configuration
    print("Reading configuration from zotero-config.xml...")
    config = read_config(config_path)

    print(f"Group ID: {config['groupid']}")
    print(f"Last modified version: {config['last_modified_version']}")
    print(f"Format: {config['format']}")

    # Create output directory if it doesn't exist
    output_dir = 'zotero_data'
    Path(output_dir).mkdir(exist_ok=True)
    print(f"Output directory: {output_dir}/")

    # Build command to run zotero_export_tool.py
    cmd = [
        sys.executable,  # Use the same Python interpreter
        'zotero_export_tool.py',
        '--id', config['groupid'],
        '--path', f'{output_dir}/',
        '--modpath', config_path
    ]

    print("\nStarting download...")
    print(f"Command: {' '.join(cmd)}")
    print("-" * 80)

    # Run the zotero export tool
    try:
        result = subprocess.run(cmd, check=True, capture_output=False, text=True)
        print("-" * 80)
        print("\nDownload completed successfully!")
        print(f"Data saved to: {output_dir}/")

    except subprocess.CalledProcessError as e:
        print(f"\nError: Download failed with exit code {e.returncode}")
        sys.exit(1)
    except FileNotFoundError:
        print("\nError: zotero_export_tool.py not found in the current directory.")
        sys.exit(1)

if __name__ == '__main__':
    main()
