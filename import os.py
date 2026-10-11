import os
from flask import Flask, jsonify
from flask_cors import CORS
from pymongo import MongoClient  # Import MongoDB Driver

app = Flask(__name__)
CORS(app)  # Allows Flutter Web to call this API without CORS errors

# 🔌 MONGODB CONNECTION SETUP
# Connects to your local MongoDB server running on the standard port 27017
MONGO_URI = "mongodb://localhost:27017/"
client = MongoClient(MONGO_URI)

# Select/Create database and collection
db = client["vocab_db"]
vocab_collection = db["words"]

DEFAULT_VOCAB = [
    {"word": "Ephemeral", "definition": "Lasting for a very short time.", "example": "The blossom on the cherry trees is beautiful.", "learned": False},
    {"word": "Serendipity", "definition": "The occurrence of valuable events by chance in a happy way.", "example": "We found the restaurant by serendipity.", "learned": False},
    {"word": "Capricious", "definition": "Given to sudden and unaccountable changes of mood.", "example": "The justice here is highly capricious.", "learned": False},
    {"word": "catch", "definition": "to get hold of an item or thing", "example": "Catch a Ball", "learned": False}
]

def seed_database_if_empty():
    """Seeds default words into MongoDB if the collection has 0 items."""
    if vocab_collection.count_documents({}) == 0:
        print("🌱 MongoDB collection is empty. Seeding default vocabulary words...")
        vocab_collection.insert_many(DEFAULT_VOCAB)

@app.route('/api/words', methods=['GET'])
def get_words_api():
    """Fetches documents dynamically from MongoDB and transforms them into JSON."""
    try:
        # Pull all documents out of the MongoDB collection
        mongo_words = list(vocab_collection.find({}, {"_id": 0}))  # {"_id": 0} hides MongoDB's internal ID object
        return jsonify(mongo_words), 200
    except Exception as e:
        print(f"❌ MongoDB Fetch Error: {str(e)}")
        return jsonify({"error": "Failed to read database", "details": str(e)}), 500

if __name__ == '__main__':
    # Ensure database has starting words
    seed_database_if_empty()
    
    print("🚀 Vocab MongoDB Backend Server starting on http://localhost:5000")
    app.run(debug=True, host='0.0.0.0', port=5000)
