#!/bin/bash

# Script to set up a Flask web application for the URL Safety Checker

# --- Constants ---
APP_NAME="url_safety_checker_app"
VENV_NAME="venv"
FLASK_APP_FILE="app.py"
CSV_FILE="url_dataset.csv"

# --- Functions ---

# Function to create the virtual environment
create_venv() {
    echo "Creating virtual environment..."
    python3 -m venv $VENV_NAME
    if [ $? -ne 0 ]; then
        echo "Failed to create virtual environment."
        exit 1
    fi
    echo "Virtual environment created successfully!"
}

# Function to activate the virtual environment
activate_venv() {
    echo "Activating virtual environment..."
    source $VENV_NAME/bin/activate
    if [ -z "$VIRTUAL_ENV" ]; then
        echo "Failed to activate virtual environment."
        exit 1
    fi
    echo "Virtual environment activated!"
}

# Function to install dependencies
install_dependencies() {
    echo "Installing dependencies (pandas, scikit-learn, Flask)..."
    pip install pandas scikit-learn Flask
    if [ $? -ne 0 ]; then
        echo "Failed to install dependencies."
        exit 1
    fi
    echo "Dependencies installed successfully!"
}

# Function to create the Flask application file (app.py)
create_flask_app() {
  echo "Creating Flask application file ($FLASK_APP_FILE)..."
  cat > $FLASK_APP_FILE <<EOL
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
import warnings
import socket
import ssl
from urllib.parse import urlparse
from flask import Flask, request, render_template, jsonify
import os

# Suppress warnings for cleaner output
warnings.filterwarnings("ignore")

# Initialize Flask app
app = Flask(__name__)

# Initialize model and dataset globals
model = None
label_encoder = LabelEncoder()
X = None
csv_file_path = 'url_dataset.csv'  # Define the CSV file path globally

# Feature Extraction Functions
def ssl_certificate_valid(url):
    try:
        hostname = urlparse(url).netloc
        if not hostname:
            return 0  # Handle URLs without a valid hostname
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
        if not domain:
            return 0  # Handle URLs without a valid domain
        socket.gethostbyname(domain)
        return 1
    except:
        return 0

def extract_features(url):
    return [
        ssl_certificate_valid(url),
        dns_lookup(url),
    ]

# Function to load dataset and train model
def load_and_train_model(csv_file=csv_file_path):
    global model, X

    if not os.path.exists(csv_file):
        raise FileNotFoundError(f"Error ❌: CSV file '{csv_file}' not found.")

    try:
        dataset = pd.read_csv(csv_file)
    except pd.errors.EmptyDataError:
        raise pd.errors.EmptyDataError("CSV file is empty ❌. Add URLs and labels to train the model.")
    except FileNotFoundError:
        raise FileNotFoundError("CSV file not found ❌. Create 'url_dataset.csv' with the correct columns.")

    # --- Option A: Use features from Python ---
    expected_columns_a = ['url', 'ssl_certificate_valid', 'dns_lookup', 'label']
    if not all(col in dataset.columns for col in expected_columns_a):
        raise ValueError(f"Error ❌: CSV file must contain columns: {', '.join(expected_columns_a)} for Option A")

    dataset.dropna(inplace=True)  # remove null values
    if dataset.empty:
        raise ValueError("Dataset is empty after removing rows with missing values. ❌")

    X = dataset[['ssl_certificate_valid', 'dns_lookup']]
    y = dataset['label']
    y = label_encoder.fit_transform(y)
    X = X.apply(pd.to_numeric, errors='coerce').dropna()  # convert to numeric and drop NaN
    y = y[X.index]

    if X.empty:
        raise ValueError("No valid data to train the model. ❌")

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)

# --- OPTION A:  Use features from Python script ---
def predict_url(url):
    if model is None or X is None:
        raise Exception("Model not trained yet ❌. Ensure 'url_dataset.csv' exists and has labeled data, then run load_and_train_model().")
    features = extract_features(url)
    features_df = pd.DataFrame([features], columns=X.columns)
    prediction = model.predict(features_df)[0]
    return label_encoder.inverse_transform([prediction])[0]
# --- END OPTION A ---

def check_url_safety(url, csv_file=csv_file_path):
    """
    Checks the safety of a given URL using a trained machine learning model.

    Args:
        url (str): The URL to check.
        csv_file (str, optional): The path to the CSV file containing the dataset.
            Defaults to 'url_dataset.csv'.

    Returns:
        str: A message indicating whether the URL is "Safe" or "Malicious",
             or an error message if the model hasn't been trained.
    """
    global model  # Access the global model variable

    if model is None:
        load_and_train_model(csv_file)  # Load and train the model if it hasn't been already

    # Check if the URL is in the dataset
    dataset = pd.read_csv(csv_file)
    if url not in dataset['url'].values:
        print(f"\n❓ The URL '{url}' is not found in the dataset.")
        user_input = input("Would you like to add it to the database? (y/n): ").strip().lower()
        if user_input == 'y':
            label = input("Please specify if the URL is 'Safe' or 'Malicious': ").strip().capitalize()
            while label not in ['Safe', 'Malicious']:
                label = input("Invalid input. Please specify 'Safe' or 'Malicious': ").strip().capitalize()

            # Extract features and create the new data entry
            features = extract_features(url)
            new_data = {
                'url': url,
                'ssl_certificate_valid': features[0],
                'dns_lookup': features[1],
                'label': label
            }

            # Append the new data to the dataset using pd.concat
            dataset = pd.concat([dataset, pd.DataFrame([new_data])], ignore_index=True)
            dataset.to_csv(csv_file, index=False)
            print(f"✅ The URL '{url}' has been added to the dataset as '{label}'.")
    try:
        prediction = predict_url(url)
        if prediction == "Safe":
            return f"✅ The URL '{url}' is classified as: \033[92m{prediction}\033[0m ✅"  # Green for Safe
        else:
            return f"⚠️ The URL '{url}' is classified as: \033[91m{prediction}\033[0m ⚠️"  # Red for Malicious
    except Exception as e:
        return f"❌ Error: {str(e)}"



# Route to handle URL safety checks
@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        url_to_check = request.form['url']
        result = check_url_safety(url_to_check)
        return render_template('index.html', result=result, url=url_to_check)
    return render_template('index.html', result=None, url=None)

# Route to handle model training
@app.route('/train', methods=['POST'])
def train():
    try:
        load_and_train_model()
        return jsonify({'message': 'Model trained successfully!'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == "__main__":
    # Load and train the model when the app starts
    try:
        load_and_train_model()
        print("Model loaded and trained successfully.")
    except Exception as e:
        print(f"Error during model loading/training: {e}")
        # Optionally, you could choose to not start the app if the model fails to load.
        # exit(1)

    app.run(debug=True, host='0.0.0.0')
EOL
  if [ $? -ne 0 ]; then
    echo "Failed to create Flask application file."
    exit 1
  fi
  echo "Flask application file created!"
}

# Function to create the index.html template
create_index_template() {
    echo "Creating index.html template..."
    mkdir -p templates #make sure the directory exists
    cat > templates/index.html <<EOL
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>URL Safety Checker</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
    <script src="https://unpkg.com/@tailwindcss/browser@latest"></script>
    <style>
      body {
        font-family: 'Inter', sans-serif;
      }
    </style>
</head>
<body class="bg-gradient-to-r from-blue-200 to-indigo-200 min-h-screen flex justify-center items-center">
    <div class="bg-white rounded-lg shadow-xl p-8 w-full max-w-md transition-transform hover:scale-105">
        <h1 class="text-2xl font-semibold text-blue-600 text-center mb-6">URL Safety Checker</h1>
        <form method="POST" action="/" class="mb-4 space-y-4">
            <div>
                <label for="url" class="block text-gray-700 text-sm font-bold mb-2">Enter URL:</label>
                <input type="text" id="url" name="url" placeholder="https://www.example.com" required
                       class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline">
            </div>
            <button type="submit" class="bg-gradient-to-r from-green-400 to-blue-500 hover:from-green-500 hover:to-blue-600 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline w-full transition duration-300 ease-in-out">
                Check Safety
            </button>
        </form>
        <div id="result" class="text-center mt-6">
            {% if result %}
                <p class="{{ 'text-green-600' if 'Safe' in result else 'text-red-600' }} font-semibold text-lg">
                    {{ result | safe }}
                </p>
                 <p class="text-gray-500 text-sm mt-2">
                    Checked URL: {{ url }}
                </p>
            {% else %}
                <p class="text-gray-500 italic">Enter a URL to check its safety.</p>
            {% endif %}
        </div>
    </div>
</body>
</html>
EOL
    if [ $? -ne 0 ]; then
        echo "Failed to create index.html template."
        exit 1
    fi
    echo "Index.html template created!"
}



# Function to run the application
run_app() {
    echo "Running the Flask application..."
    python $FLASK_APP_FILE
}

# --- Main Script ---

# Check if the CSV file exists
if [ ! -f "$CSV_FILE" ]; then
  echo "Error: CSV file '$CSV_FILE' not found. Please create it before running this script."
  exit 1
fi

create_venv
activate_venv
install_dependencies
create_flask_app
create_index_template
run_app
