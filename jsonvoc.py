import json
import os
from flask import Flask, jsonify
from flask_cors import CORS

# Initialize Flask cleanly
app = Flask(__name__)

# Enforce global network CORS exceptions so your physical Oppo phone can connect safely
CORS(app, resources={r"/*": {"origins": "*"}})

DATA_FILE = "vocabulary.json"

DEFAULT_VOCAB = {
    "total": 1,
    "words": [
        {
            "id": 1,
            "word": "Ephemeral",
            "definition": "Lasting for a very short time.",
            "example": "The blossom on the cherry trees is beautiful but ephemeral.",
            "current_status": "reviewing"
        }
    ]
}

def load_vocab():
    if os.path.exists(DATA_FILE):
        try:
            with open(DATA_FILE, "r", encoding="utf-8") as file:
                data = json.load(file)
                
                # FIX: If your vocabulary.json file is a raw list, wrap it to match your Flutter parser
                if isinstance(data, list):
                    return {"total": len(data), "words": data}
                return data
        except Exception as e:
            print(f"⚠️ JSON parsing failed ({e}). Using default backup data.")
            return DEFAULT_VOCAB
    return DEFAULT_VOCAB

# Match the exact routing path targeted by your Flutter app
@app.route('/api/words', methods=['GET'])
def get_words_api():
    payload = load_vocab()
    return jsonify(payload)

if __name__ == '__main__':
    print("🚀 Vocab Backend Server broadcasting live on port 8000")
    
    # FIX: Changed host from '127.0.0.1' to '0.0.0.0' to open it up to your local Wi-Fi network
    app.run(debug=True, host='0.0.0.0', port=8000)
