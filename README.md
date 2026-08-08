## Features
  - Subdomain enumeration (subfinder)
  - Live host probing with tech detection (httpx)
  - JavaScript extraction (katana - medium/full modes)
  - Vulnerability scanning (nuclei - full mode)
  - Organized output in `./results/<domain>/`

## Usage
  ```bash
  ./recon.sh <domain> [quick|medium|full]
  - quick: subfinder + httpx
  - medium: + katana (JS files)
  - full: + nuclei (vuln scan)

  Example:
  ./recon.sh example.com full
