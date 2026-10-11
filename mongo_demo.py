from flask import Flask, jsonify, request
from flask_pymongo import PyMongo
from bson.objectid import ObjectId

app = Flask(__name__)

# Configure MongoDB connection to your local instance
app.config["MONGO_URI"] = "mongodb://localhost:27017/vocab_db"
mongo = PyMongo(app)

# Helper function to seed data (similar to your seed_database_if_empty function)
def seed_database_if_empty():
    vocab_collection = mongo.db.vocabulary
    if vocab_collection.count_documents({}) == 0:
        print("Database is empty. Seeding initial data...")
        sample_data = [
            {"word": "Database", "definition": "An organized collection of data."},
            {"word": "Flask", "definition": "A micro web framework written in Python."},
            {"word": "MongoDB", "definition": "A source-available cross-platform document-oriented database program."}
        ]
        vocab_collection.insert_many(sample_data)
        print("Seeding complete.")

# 1. Route to get all vocabulary items
@app.route("/vocab", methods=["GET"])
def get_all_vocab():
    vocab_collection = mongo.db.vocabulary
    output = []
    for doc in vocab_collection.find():
        output.append({
            "id": str(doc["_id"]),
            "word": doc.get("word"),
            "definition": doc.get("definition")
        })
    return jsonify({"success": True, "data": output})

# 2. Route to add a new vocabulary item
@app.route("/vocab", methods=["POST"])
def add_vocab():
    vocab_collection = mongo.db.vocabulary
    data = request.get_json()
    
    if not data or "word" not in data or "definition" not in data:
        return jsonify({"success": False, "error": "Missing word or definition"}), 400
        
    new_doc = {
        "word": data["word"],
        "definition": data["definition"]
    }
    result = vocab_collection.insert_one(new_doc)
    
    return jsonify({
        "success": True, 
        "message": "Word added successfully!",
        "inserted_id": str(result.inserted_id)
    }), 201

if __name__ == "__main__":
    # Ensure app context is active to access mongo configuration during startup
    with app.app_context():
        seed_database_if_empty()
        
    # Start the Flask development server
    app.run(debug=True, port=5001)
