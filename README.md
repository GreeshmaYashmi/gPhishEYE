🕵️‍♂️ gPhishEYE

gPhishEYE is a simple tool to detect malicious URLs using Machine Learning and basic security checks (SSL certificate, DNS lookup, Google Safe Browsing API).
📦 Installation

    Create a virtual environment (recommended):
    Bash

python3 -m venv myenv

Activate the virtual environment:

    On Linux/macOS:
    Bash

source myenv/bin/activate

On Windows:
Bash

    myenv\Scripts\activate

Install required dependencies:
Bash

    pip install -r requirements.txt

📄 Setup the Dataset

Before running, you need a dataset file named url_dataset.csv in the same folder.

Create a file url_dataset.csv with the following structure:
Code snippet

url,ssl_certificate_valid,dns_lookup,google_safe_browsing,label
https://www.google.com,1,1,0,safe
http://phishing-site-example.com,0,0,1,malicious

    ssl_certificate_valid: 1 if valid SSL cert, 0 otherwise.
    dns_lookup: 1 if domain resolves, 0 otherwise.
    google_safe_browsing: 1 if flagged as malicious, 0 otherwise.
    label: safe or malicious.

✅ You need at least 10-15 URLs to train a basic model.

🚀 How to Run

    Activate the virtual environment (if not already):
    Bash

source myenv/bin/activate

Run the gPhishEYE tool:
Bash

    python3 gphisheye.py

Usage:

When prompted, paste one or more URLs separated by commas.

Example:

🔗 Paste your URLs (comma-separated) or type 'exit' to quit.
👉 https://google.com, http://some-malicious-site.com

Results:

    The tool checks SSL, DNS, and Safe Browsing status.
    It predicts if the URL is Safe or Malicious.
    It also automatically appends new checked URLs back into url_dataset.csv for future training.

📜 Requirements

    Python 3.8+
    Libraries:
        pandas
        scikit-learn
        requests

These are already listed in requirements.txt.

If missing, you can manually install:
Bash

pip install pandas scikit-learn requests

Or simply:
Bash

pip install -r requirements.txt

🔑 Google Safe Browsing API

To fully utilize Safe Browsing detection:

    Replace the API_KEY variable inside gphisheye.py with your valid Google API key.
    Without the API key, Safe Browsing checks may fail.

👉 How to get a Google API key

⚠️ Common Problems
Issue	Solution
CSV file not found	Create a valid url_dataset.csv.
n_samples=0 error	You need to add more URLs into the CSV to train the model.
test_size=0.2 error with few samples	Add more data points (>5 URLs minimum).
name 'X' is not defined	Make sure your dataset exists before prediction.

🎯 Quick Commands Summary
Bash

# Clone the repo
git clone https://github.com/yourusername/gPhishEYE.git
cd gPhishEYE

# Create and activate virtual environment
python3 -m venv myenv
source myenv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run the tool
python3 gphisheye.py

👨‍💻 Contribution

PRs are welcome!
Found a bug or have ideas to improve? Feel free to open an issue or submit a pull request.

📜 License

This project is for educational purposes only.
Use it responsibly! 🚀
