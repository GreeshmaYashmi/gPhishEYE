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
    git clone https://github.com/GreeshmaYashmi/gPhishEYE.git &&
    cd gPhishEYE
    ```

3.  **Install Dependencies:**
    Install the required Python packages using pip:
    ```bash
    pip install pandas scikit-learn
    ```

4. **Install front-end:**
   Install flask automation script:
   ```bash
   chmod +x flash.sh
   ```
   ```bash
   ./flash.sh
   ```
   And visit this URL in your website to acess my website :
   ```http
   http://127.0.0.1:5000
   ```
## Usage

1.  **Run the Script:(cli)**
    Open a terminal or command prompt and navigate to the directory where you saved the script (e.g., `url_safety_checker.py`).  Then, run the script:
    ```bash
    python gphisheye.py
    ```
    Open a terminal and navigate to the working dir then :
    ```bash
    python3 app.py
    ```
    for website !

3.  **Enter a URL:**
    The script will prompt you to enter a URL to check:
    ```
    Enter the URL to check:
    ```

4.  **View the Result:**
    The script will then display the classification of the URL:
    * If the URL is classified as safe:
        ```
        ✅  The URL '[https://www.google.com](https://www.google.com)' is classified as: Safe ✅
        ```
    * If the URL is classified as malicious:
        ```
        ⚠️  The URL '[http://www.example.com](http://www.example.com)' is classified as: Malicious ⚠️
        ```

## Gallery

<br>

<div style="display: flex; flex-wrap: wrap; justify-content: space-around;">
    <img src="https://github.com/GreeshmaYashmi/gPhishEYE/blob/main/images/Screenshot%20From%202025-04-27%2016-46-02.png" alt="Screenshot 1" style="margin: 10px; max-width: 45%; height: auto;">
    <img src="https://github.com/GreeshmaYashmi/gPhishEYE/blob/main/images/Screenshot%20From%202025-04-27%2017-04-53.png" alt="Screenshot 2" style="margin: 10px; max-width: 45%; height: auto;">
    <img src="https://github.com/GreeshmaYashmi/gPhishEYE/blob/main/images/Screenshot%20From%202025-04-27%2017-04-53.png" alt="Screenshot 3" style="margin: 10px; max-width: 45%; height: auto;">
    <img src="https://github.com/GreeshmaYashmi/gPhishEYE/blob/main/images/Screenshot%20From%202025-04-27%2017-04-53.png" alt="Screenshot 4" style="margin: 10px; max-width: 45%; height: auto;">
</div>

<br>


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
