# Speedtest CLI Script

This directory contains a shell script for logging network speed test results over time using the Speedtest CLI tool.

## Installation

### 1. Install Speedtest CLI

The script uses the official [Speedtest CLI](https://www.speedtest.net/apps/cli) tool. Choose your installation method based on your operating system:

#### macOS (using Homebrew)
```bash
brew install speedtest-cli
```

#### Linux (Debian/Ubuntu)
```bash
sudo apt-get install speedtest-cli
```

#### Linux (Fedora/RHEL)
```bash
sudo dnf install speedtest-cli
```

#### Linux (using pip)
```bash
pip install speedtest-cli
```

#### Manual Installation (All platforms)
Download from the official Speedtest website or install via pip:
```bash
pip install speedtest-cli
```

### 2. Make the script executable
```bash
chmod +x speedtest/speedlog.sh
```

## Usage

### Finding Server IDs

First, list available Speedtest servers to find a server ID:
```bash
speedtest -L
```

This will display all available test servers. Each server has an ID number that you'll use with the script.

### Running the Script

Run the script with a server ID as an argument:
```bash
./speedlog.sh <server_id>
```

**Example:**
```bash
./speedlog.sh 1234
```

### Output

The script performs a speed test and logs the results to a CSV file (`speedlog.csv`) in the same directory with the following columns:
- **Date** (YYYY-MM-DD format)
- **Time** (HH:MM format)
- Speed test results (download speed, upload speed, etc.)

### Scheduling Regular Tests

To run speed tests automatically at regular intervals, add a cron job:

```bash
# Edit your crontab
crontab -e
```

Add a line to run the test every hour at a specific server (example: every hour at the top of the hour):
```bash
0 * * * * cd /path/to/speedtest && ./speedlog.sh 1234
```

Or run every 30 minutes:
```bash
*/30 * * * * cd /path/to/speedtest && ./speedlog.sh 1234
```

## Example

```bash
$ ./speedlog.sh 1234
Running speedtest on server 1234...
# Results are appended to speedlog.csv
```

View your speed test history:
```bash
cat speedlog.csv
```

## Tips

- **Consistent monitoring**: Use cron to schedule regular tests at fixed intervals to build a historical record
- **Multiple servers**: Run tests against different servers to understand regional performance variations
- **Data analysis**: Parse `speedlog.csv` with tools like Excel, Python pandas, or awk for trend analysis
- **Automated alerts**: Combine with monitoring scripts to alert if speeds drop below expected thresholds
