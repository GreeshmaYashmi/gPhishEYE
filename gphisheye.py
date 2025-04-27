import pandas as pd
import socket
import ssl
import requests
from urllib.parse import urlparse
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, accuracy_score
from sklearn.preprocessing import LabelEncoder
import os
import warnings

# Suppress warnings for cleaner output
warnings.filterwarnings("ignore")

# Google Safe Browsing API Key (Insert your own key)
API_KEY = 'AIzaSyD-8LxpF5g4CdDYs4GWxBxdoz_g7aBVPmU'

# Initialize model and dataset globals
model = None
X = None
label_encoder = LabelEncoder()

# Feature Extraction Functions
def ssl_certificate_valid(url):
    try:
        hostname = urlparse(url).netloc
        ctx = ssl.create_default_context()
        with ctx.wrap_socket(socket.socket(), server_hostname=hostname) as s:
            s.settimeout(3.0)
            s.connect((hostname, 443))
            cert = s.getpeercert()
            return 1
    except Exception:
        return 0

def dns_lookup(url):
    try:
        domain = urlparse(url).netloc
        socket.gethostbyname(domain)
        return 1
    except:
        return 0

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
            "threatEntries": [{"url": url}]
        }
    }
    try:
        response = requests.post(api_url, json=payload)
        if response.status_code == 200:
            threats = response.json().get('matches')
            return 1 if threats else 0
        else:
            return 0
    except requests.exceptions.RequestException:
        return 0

def extract_features(url):
    return [
        ssl_certificate_valid(url),
        dns_lookup(url),
        google_safe_browsing_check(url)
    ]

# Function to load dataset and train model
def load_and_train_model():
    global model, X

    if not os.path.exists('url_dataset.csv'):
        print("CSV file not found. Creating new one...")
        with open('url_dataset.csv', 'w') as f:
            f.write('url,ssl_certificate_valid,dns_lookup,google_safe_browsing,label\n')
        print("Empty CSV created. Please start adding URLs.")

    dataset = pd.read_csv('url_dataset.csv')

    expected_columns = ['url', 'ssl_certificate_valid', 'dns_lookup', 'google_safe_browsing', 'label']
    if any(col not in dataset.columns for col in expected_columns):
        raise ValueError("CSV file is missing required columns.")

    if dataset.empty:
        print("Dataset is empty. Please add URLs to train the model.")
        print("⚠️ Warning: New URLs will be treated as malicious until model is trained!")
        model = None
        X = None
    else:
        X = dataset[['ssl_certificate_valid', 'dns_lookup', 'google_safe_browsing']]
        y = dataset['label']
        y = label_encoder.fit_transform(y)

        X = X.apply(pd.to_numeric, errors='coerce')

        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

        model = RandomForestClassifier(n_estimators=100, random_state=42)
        model.fit(X_train, y_train)

        y_pred = model.predict(X_test)
        print("\n📈 Model trained successfully!")
        print("Accuracy:", accuracy_score(y_test, y_pred))
        print(classification_report(y_test, y_pred))

def predict_url(url):
    if model is None or X is None:
        raise Exception("Model not trained yet. Please add URLs first.")

    features = extract_features(url)
    features_df = pd.DataFrame([features], columns=X.columns)
    prediction = model.predict(features_df)[0]
    return "Malicious" if prediction == 1 else "Safe", features

def append_to_csv(url, prediction, features):
    new_data = {
        'url': url,
        'ssl_certificate_valid': features[0],
        'dns_lookup': features[1],
        'google_safe_browsing': features[2],
        'label': prediction
    }
    new_df = pd.DataFrame([new_data])
    file_exists = os.path.isfile('url_dataset.csv')
    new_df.to_csv('url_dataset.csv', mode='a', header=not file_exists, index=False)

# Main interactive loop
if __name__ == "__main__":
    load_and_train_model()

    while True:
        print("\n🔗 Paste your URLs (comma-separated) or type 'exit' to quit.")
        urls_input = input("👉 ")

        if urls_input.lower() == 'exit':
            print("Goodbye! 👋")
            break

        url_list = [url.strip() for url in urls_input.split(',') if url.strip()]

        if not url_list:
            print("⚠️ No URLs entered. Please try again.")
            continue

        print("\n🔎 Checking URLs...\n")

        for url in url_list:
            try:
                if model is None:
                    features = extract_features(url)
                    prediction = "Malicious"  # Assume unknown URLs are malicious
                    print(f"{url} --> {prediction} (Model not ready)")
                    append_to_csv(url, prediction, features)
                else:
                    prediction, features = predict_url(url)
                    print(f"{url} --> {prediction}")
                    append_to_csv(url, prediction, features)

            except Exception as e:
                print(f"⚠️ Error checking {url}: {e}")

        # After adding new URLs, reload model if needed
        load_and_train_model()
