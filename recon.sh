#!/bin/bash

# Recon Automation Script
# Runs: subfinder -> httpx -> katana (JS extraction) -> nuclei
# Organized output in ./results/<domain>/

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
DOMAIN=""
MODE="medium" # quick, medium, full

# Function to display usage
usage() {
    echo -e "${YELLOW}Usage: $0 <domain> [quick|medium|full]${NC}"
    echo -e "Example: $0 example.com full"
    exit 1
}

# Check if domain is provided
if [ -z "$1" ]; then
    usage
fi

DOMAIN="$1"
MODE="${2:-medium}"

# Validate mode
if [[ ! "$MODE" =~ ^(quick|medium|full)$ ]]; then
    echo -e "${RED}Error: Mode must be quick, medium, or full${NC}"
    usage
fi

# Check for required tools
check_tool() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}��❌ $1 not found. Please install it.${NC}"
        exit 1
    fi
}

echo -e "${BLUE}[*] Checking required tools...${NC}"
check_tool subfinder
check_tool httpx
check_tool katana
check_tool nuclei

# Create results directory
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULTS_DIR="./results/${DOMAIN}"
mkdir -p "$RESULTS_DIR"
echo -e "${BLUE}[*] Results will be stored in: $RESULTS_DIR${NC}"

# Step 1: Subdomain Enumeration
echo -e "${BLUE}[*] Step 1: Enumerating subdomains with subfinder${NC}"
subfinder -d "$DOMAIN" -silent -o "${RESULTS_DIR}/subdomains.txt"
SUBDOMAIN_COUNT=$(wc -l < "${RESULTS_DIR}/subdomains.txt")
echo -e "${GREEN}[+] Found $SUBDOMAIN_COUNT subdomains${NC}"

# Step 2: Probe Live Hosts
echo -e "${BLUE}[*] Step 2: Probing live hosts with httpx${NC}"
httpx -l "${RESULTS_DIR}/subdomains.txt" -status-code -title -tech-detect -follow-redirects -silent -o "${RESULTS_DIR}/httpx.txt"
LIVE_COUNT=$(wc -l < "${RESULTS_DIR}/httpx.txt")
echo -e="${GREEN}[+] Found $LIVE_COUNT live hosts${NC}"

# Extract live URLs (first column) for further processing
cut -d' ' -f1 "${RESULTS_DIR}/httpx.txt" > "${RESULTS_DIR}/live.txt"

# Step 3: JS Extraction and Nuclei (based on mode)
if [[ "$MODE" == "medium" || "$MODE" == "full" ]]; then
    echo -e "${BLUE}[*] Step 3: Extracting JavaScript files with katana${NC}"
    katana -list "${RESULTS_DIR}/live.txt" -js -silent -o "${RESULTS_DIR}/js.txt"
    JS_COUNT=$(wc -l < "${RESULTS_DIR}/js.txt")
    echo -e "${GREEN}[+] Found $JS_COUNT JavaScript files${NC}"
fi

if [[ "$MODE" == "full" ]]; then
    echo -e "${BLUE}[*] Step 4: Running nuclei vulnerability scan${NC}"
    nuclei -l "${RESULTS_DIR}/live.txt" -t vulnerabilities/ -t exposures/ -t misconfiguration/ -severity low,medium,high,critical -silent -o "${RESULTS_DIR}/nuclei.txt"
    NUCLEI_COUNT=$(wc -l < "${RESULTS_DIR}/nuclei.txt")
    echo -e "${GREEN}[+] Found $NUCLEI_COUNT potential vulnerabilities${NC}"
fi

# Summary
echo -e "${BLUE}[*] Recon complete!${NC}"
echo -e "${BLUE}[*] Summary for $DOMAIN:${NC}"
echo -e "  • Subdomains: $SUBDOMAIN_COUNT"
echo -e "  • Live hosts: $LIVE_COUNT"
if [[ "$MODE" == "medium" || "$MODE" == "full" ]]; then
    echo -e "  • JavaScript files: $JS_COUNT"
fi
if [[ "$MODE" == "full" ]]; then
    echo -e "  • Nuclei findings: $NUCLEI_COUNT"
fi
echo -e "${BLUE}[*] Results saved in: $RESULTS_DIR${NC}"