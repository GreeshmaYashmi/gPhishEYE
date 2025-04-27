#!/bin/bash

# Setup script for URL Safety Checker Dashboard

echo "🚀 Starting setup..."

# Step 1: Create virtual environment (optional but good practice)
python3 -m venv venv
source venv/bin/activate

# Step 2: Install required Python packages
echo "📦 Installing dependencies..."
pip install flask pandas scikit-learn requests

# Step 3: Create project folder structure
mkdir -p templates

# Step 4: Create app.py
echo "🛠 Creating app.py..."
cat > app.py << 'EOF'
from flask import Flask, render_template, request
import pandas as pd
import socket
import ssl
import requests
from urllib.parse import urlparse
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder
import os
import warnings

warnings.filterwarnings("ignore")
app = Flask(__name__)

API_KEY = 'YOUR_API_KEY_HERE'

model = None
X = None
label_encoder = LabelEncoder()

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

def load_and_train_model():
    global model, X
    if not os.path.exists('url_dataset.csv'):
        print("CSV not found. Creating new...")
        with open('url_dataset.csv', 'w') as f:
            f.write('url,ssl_certificate_valid,dns_lookup,google_safe_browsing,label\n')

    dataset = pd.read_csv('url_dataset.csv')
    expected_columns = ['url', 'ssl_certificate_valid', 'dns_lookup', 'google_safe_browsing', 'label']
    if any(col not in dataset.columns for col in expected_columns):
        raise ValueError("CSV file missing required columns.")

    if dataset.empty:
        print("Dataset empty. Add URLs to train model.")
        model = None
        X = None
    else:
        X = dataset[['ssl_certificate_valid', 'dns_lookup', 'google_safe_browsing']]
        y = dataset['label']
        y = label_encoder.fit_transform(y)

        X = X.apply(pd.to_numeric, errors='coerce')

        model = RandomForestClassifier(n_estimators=100, random_state=42)
        model.fit(X, y)
        print("Model trained.")

def predict_url(url):
    if model is None or X is None:
        return "Model not trained.", []

    features = extract_features(url)
    features_df = pd.DataFrame([features], columns=X.columns)
    prediction = model.predict(features_df)[0]
    return "Malicious" if prediction == 1 else "Safe", features

@app.route('/', methods=['GET', 'POST'])
def index():
    result = None
    if request.method == 'POST':
        url = request.form['url']
        prediction, features = predict_url(url)
        result = {
            'url': url,
            'prediction': prediction,
            'features': features
        }
    return render_template('index.html', result=result)

if __name__ == '__main__':
    load_and_train_model()
    app.run(debug=True)
EOF

# Step 5: Create index.html
echo "🖌 Creating templates/index.html..."
cat > templates/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>URL Safety Checker</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">

<div class="container mt-5">
    <h1 class="text-center mb-4">🔎 URL Safety Checker Dashboard</h1>

    <div class="card p-4 shadow-sm">
        <form method="POST">
            <div class="mb-3">
                <label for="url" class="form-label">Enter URL to Check:</label>
                <input type="text" class="form-control" id="url" name="url" placeholder="https://example.com" required>
            </div>
            <button type="submit" class="btn btn-primary">Check URL</button>
        </form>
    </div>

    {% if result %}
    <div class="card mt-4 p-4 shadow-sm">
        <h4>🔗 URL: {{ result.url }}</h4>
        <h5>Status: 
            {% if result.prediction == 'Safe' %}
                <span class="badge bg-success">{{ result.prediction }}</span>
            {% else %}
                <span class="badge bg-danger">{{ result.prediction }}</span>
            {% endif %}
        </h5>
        <hr>
        <h6>Extracted Features:</h6>
        <ul>
            <li>SSL Certificate Valid: {{ result.features[0] }}</li>
            <li>DNS Lookup: {{ result.features[1] }}</li>
            <li>Google Safe Browsing Check: {{ result.features[2] }}</li>
        </ul>
    </div>
    {% endif %}
</div>

</body>
</html>
EOF

# Step 6: Create empty CSV if it doesn't exist
if [ ! -f url_dataset.csv ]; then
    echo "url,ssl_certificate_valid,dns_lookup,google_safe_browsing,label" > url_dataset.csv
fi

echo "✅ Setup complete!"
echo "🌐 Starting Flask app at http://127.0.0.1:5000"

# Step 7: Launch Flask app
python app.py
