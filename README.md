# 🕵️‍♂️ gPhishEYE

gPhishEYE is a simple tool to detect malicious URLs using Machine Learning and basic security checks (SSL certificate, DNS lookup, Google Safe Browsing API).
📦 Installation

## Overview

The gPhishEYE is a Python script that classifies URLs as either safe or malicious. It uses a machine learning model (Random Forest) trained on a dataset of URLs and their corresponding safety labels.  The script extracts features from a given URL, such as SSL certificate validity and DNS lookup status, to make its prediction.

## Features

* **URL Safety Classification:** Classifies URLs as "Safe" or "Malicious".
* **Machine Learning Powered:** Uses a Random Forest classifier for accurate predictions.
* **Feature Extraction:** Extracts relevant features from URLs (SSL certificate, DNS lookup).
* **Data-Driven:** Relies on a CSV dataset (`url_dataset.csv`) for training.
* **Error Handling:** Includes robust error handling for missing files, empty data, and invalid URLs.
* **Command-Line Interface:** Simple command-line interface for checking URL safety.
* **Informative Output:** Provides clear output with emojis and color-coded results (Safe - Green, Malicious - Red).

## Installation

1.  **Prerequisites:**
    * Python 3.x
    * pip (Python package installer)

2.  **Clone the Repository (Optional):**
    If you have the code in a Git repository, you can clone it:
    ```bash
    git clone <your_repository_url>
    cd <your_repository_directory>
    ```

3.  **Install Dependencies:**
    Install the required Python packages using pip:
    ```bash
    pip install pandas scikit-learn
    ```

## Usage

1.  **Run the Script:**
    Open a terminal or command prompt and navigate to the directory where you saved the script (e.g., `url_safety_checker.py`).  Then, run the script:
    ```bash
    python gphisheye.py
    ```

2.  **Enter a URL:**
    The script will prompt you to enter a URL to check:
    ```
    Enter the URL to check:
    ```

3.  **View the Result:**
    The script will then display the classification of the URL:
    * If the URL is classified as safe:
        ```
        ✅  The URL '[https://www.google.com](https://www.google.com)' is classified as: Safe ✅
        ```
    * If the URL is classified as malicious:
        ```
        ⚠️  The URL '[http://www.example.com](http://www.example.com)' is classified as: Malicious ⚠️
        ```

## Example Gallery

Here are a few examples of how the script classifies URLs:

* **Safe URL:**
    ```bash
    Enter the URL to check: [https://www.google.com](https://www.google.com)
    ```
    Output:
    ```
    ✅  The URL '[https://www.google.com](https://www.google.com)' is classified as: Safe ✅
    ```

* **Malicious URL:**
    ```bash
    Enter the URL to check: [http://malware.example](http://malware.example)
    ```
    Output:
    ```
    ⚠️  The URL '[http://malware.example](http://malware.example)' is classified as: Malicious ⚠️
    ```

## Credits

* **Author:** Greeshma Yashmi
* **License:** [MIT License]

## Contributions

JEJO .J : Front-end & model training 
[Add any contribution guidelines here if you want others to contribute to your project.]
