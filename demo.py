import json
import os
import random

DATA_FILE = "vocabulary.json"

# Pre-seeded vocabulary list
DEFAULT_VOCAB = [
    {
        "word": "Ephemeral",
        "definition": "Lasting for a very short time.",
        "example": "The blossom on the cherry trees is beautiful but ephemeral.",
        "learned": False
    },
    {
        "word": "Serendipity",
        "definition": "The occurrence of valuable events by chance in a happy way.",
        "example": "We found the charming little restaurant by pure serendipity.",
        "learned": False
    },
    {
        "word": "Capricious",
        "definition": "Given to sudden and unaccountable changes of mood or behavior.",
        "example": "The administration of justice here is highly capricious.",
        "learned": False
    }
]

def load_vocab():
    """Loads vocabulary from a JSON file or returns defaults if it doesn't exist."""
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE, "r") as file:
            return json.load(file)
    return DEFAULT_VOCAB

def save_vocab(vocab):
    """Saves the current vocabulary list to the JSON file."""
    with open(DATA_FILE, "w") as file:
        json.dump(vocab, file, indent=4)

def show_progress(vocab):
    """Displays how many words have been mastered."""
    total = len(vocab)
    mastered = sum(1 for item in vocab if item["learned"])
    print("\n" + "="*40)
    print(f"📊 PROGRESS: Mastered {mastered}/{total} words")
    print("="*40)

def practice_flashcards(vocab):
    """Loops through unlearned flashcards randomly."""
    unlearned = [item for item in vocab if not item["learned"]]
    
    if not unlearned:
        print("\n🎉 Outstanding! You have mastered all your vocabulary words!")
        return

    item = random.choice(unlearned)
    print(f"\n🧠 WORD: {item['word']}")
    input("Press Enter to reveal the definition...")
    
    print(f"📖 Definition: {item['definition']}")
    print(f"💬 Example:    \"{item['example']}\"")
    
    choice = input("\nDid you know this word? (y: Yes, mark Mastered / n: No, keep practicing): ").lower()
    if choice == 'y':
        item["learned"] = True
        print(f"✅ Awesome! '{item['word']}' marked as mastered.")
        save_vocab(vocab)

def add_word(vocab):
    """Prompts user to add a new word to their list."""
    print("\n➕ ADD NEW WORD")
    word = input("Enter word: ").strip()
    definition = input("Enter definition: ").strip()
    example = input("Enter an example sentence: ").strip()

    if word and definition:
        vocab.append({
            "word": word,
            "definition": definition,
            "example": example,
            "learned": False
        })
        save_vocab(vocab)
        print(f"🎉 '{word}' successfully added to your dictionary!")
    else:
        print("❌ Word and definition cannot be empty.")

def main():
    vocab = load_vocab()
    
    while True:
        show_progress(vocab)
        print("1. Practice Flashcards")
        print("2. Add a New Word")
        print("3. Reset All Progress")
        print("4. Exit")
        
        choice = input("\nChoose an option (1-4): ").strip()
        
        if choice == "1":
            practice_flashcards(vocab)
        elif choice == "2":
            add_word(vocab)
        elif choice == "3":
            confirm = input("Are you sure you want to unmark all learned words? (y/n): ").lower()
            if confirm == 'y':
                for item in vocab:
                    item["learned"] = False
                save_vocab(vocab)
                print("🔄 Progress reset complete.")
        elif choice == "4":
            print("\n👋 Happy learning! Goodbye.")
            break
        else:
            print("❌ Invalid selection. Please enter 1, 2, 3, or 4.")

if __name__ == "__main__":
    main()
    