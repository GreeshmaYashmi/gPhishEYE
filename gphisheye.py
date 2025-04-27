import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, accuracy_score
from sklearn.preprocessing import LabelEncoder
import warnings
import socket
import ssl
from urllib.parse import urlparse
import re
import os

# Suppress warnings for cleaner output
warnings.filterwarnings("ignore")

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
    y_pred = model.predict(X_test)
    print("\n📈 Model trained successfully! ✅")
    print("Accuracy:", accuracy_score(y_test, y_pred))
    print(classification_report(y_test, y_pred, target_names=label_encoder.classes_))


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


if __name__ == "__main__":
    # Provide the path to your CSV file
    csv_file_path = 'url_dataset.csv'
    load_and_train_model(csv_file_path)  # Load and train

    # Get URL input from the user
    url_to_check = input("Enter the URL to check: ")

    # Check the URL safety
    result = check_url_safety(url_to_check, csv_file_path)
    print(result)
