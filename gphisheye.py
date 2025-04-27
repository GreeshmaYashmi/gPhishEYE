import pandas as pd
import socket
import ssl
import requests
from urllib.parse import urlparse
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, accuracy_score
from sklearn.preprocessing import LabelEncoder  # Import LabelEncoder
import os

# Google Safe Browsing API Key (Insert your own key)
API_KEY = 'AIzaSyD-8LxpF5g4CdDYs4GWxBxdoz_g7aBVPmU'

# Feature Extraction Functions (simplified)
def ssl_certificate_valid(url):
    try:
        hostname = urlparse(url).netloc
        ctx = ssl.create_default_context()
        with ctx.wrap_socket(socket.socket(), server_hostname=hostname) as s:
            s.settimeout(3.0)
            s.connect((hostname, 443))
            cert = s.getpeercert()
            return 1  # SSL certificate valid
    except Exception:
        return 0  # Invalid SSL certificate

def dns_lookup(url):
    try:
        domain = urlparse(url).netloc
        socket.gethostbyname(domain)
        return 1  # DNS lookup successful
    except:
        return 0  # DNS lookup failed

def google_safe_browsing_check(url):
    api_url = f"https://safebrowsing.googleapis.com/v4/threatMatches:find?key={API_KEY}"
    payload = {
        "client": {
            "clientId": "yourcompanyname",
            "clientVersion": "1.5.2"
        },
        "threatInfo": {
            "threatTypes": ["MALWARE", "SOCIAL_ENGINEERING", "UNWANTED_SOFTWARE", "POTENTIALLY_HARMFUL_APPLICATION"],
            "platformTypes": ["ANY_PLATFORM"],
            "threatEntryTypes": ["URL"],
            "threatEntries": [
                {"url": url}
            ]
        }
    }
    try:
        response = requests.post(api_url, json=payload)
        if response.status_code == 200:
            threats = response.json().get('matches')
            return 1 if threats else 0  # Return 1 if malicious, 0 if not
        else:
            return 0  # Google Safe Browsing check failed
    except requests.exceptions.RequestException:
        return 0  # Network error

# Function to extract features from URL
def extract_features(url):
    return [
        ssl_certificate_valid(url),
        dns_lookup(url),
        google_safe_browsing_check(url)
    ]

# Load dataset and check if file exists
if not os.path.exists('url_dataset.csv'):
    print("CSV file not found, please create it first.")
else:
    dataset = pd.read_csv('url_dataset.csv')

    # Ensure dataset has required columns
    expected_columns = ['url', 'ssl_certificate_valid', 'dns_lookup', 'google_safe_browsing', 'label']
    if any(col not in dataset.columns for col in expected_columns):
        raise ValueError("CSV file is missing required columns")

    # Extract features (X) and labels (y)
    X = dataset[['ssl_certificate_valid', 'dns_lookup', 'google_safe_browsing']]
    y = dataset['label']

    # Label encoding for 'Safe' and 'Malicious' labels
    label_encoder = LabelEncoder()
    y = label_encoder.fit_transform(y)  # Convert 'Safe' -> 0, 'Malicious' -> 1

    # Ensure that all values in X are numeric
    X = X.apply(pd.to_numeric, errors='coerce')

    # Split data into training and testing
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    # Train Random Forest Classifier
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)

    # Evaluate the model
    y_pred = model.predict(X_test)
    print("Accuracy:", accuracy_score(y_test, y_pred))
    print(classification_report(y_test, y_pred))

# Function to predict whether a new URL is safe or malicious
def predict_url(url):
    features = extract_features(url)
    features_df = pd.DataFrame([features], columns=X.columns)
    prediction = model.predict(features_df)[0]
    # Convert prediction back to 'Safe'/'Malicious'
    return "Malicious" if prediction == 1 else "Safe", features

# Function to append new URL to CSV with prediction
def append_to_csv(url, prediction, features):
    new_data = {'url': url, 
                'ssl_certificate_valid': features[0], 
                'dns_lookup': features[1], 
                'google_safe_browsing': features[2], 
                'label': prediction}
    new_df = pd.DataFrame([new_data])
    
    # Append to the existing CSV (or create if doesn't exist)
    new_df.to_csv('url_dataset.csv', mode='a', header=False, index=False)

# Example of interactive input and prediction
if __name__ == "__main__":
    while True:
        print("\n🔗 Paste your URLs (comma-separated) or type 'exit' to quit.")
        urls_input = input("👉 ")

        if urls_input.lower() == 'exit':
            print("Goodbye! 👋")
            break

        # Split the input into multiple URLs
        url_list = [url.strip() for url in urls_input.split(',') if url.strip()]

        print("\n🔎 Checking URLs...\n")
        
        for url in url_list:
            try:
                prediction, features = predict_url(url)
                print(f"{url} --> {prediction}")
                
                # Append the new URL and prediction to the CSV
                append_to_csv(url, prediction, features)
                
            except Exception as e:
                print(f"⚠️ Error checking {url}: {e}")
