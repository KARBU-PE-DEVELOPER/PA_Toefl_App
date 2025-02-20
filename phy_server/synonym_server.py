from flask import Flask, jsonify, request
import nltk
from nltk.corpus import wordnet

nltk.download('wordnet')

app = Flask(__name__)

@app.route('/synonyms', methods=['GET'])
def get_synonyms():
    word = request.args.get('word')
    if not word:
        return jsonify({"error": "Word parameter is missing"}), 400

    synonyms = set()
    for syn in wordnet.synsets(word):
        for lemma in syn.lemmas():
            synonyms.add(lemma.name())  # Get synonym words

    if not synonyms:
        return jsonify({"error": "No synonyms found"}), 404

    return jsonify(list(synonyms))

if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0", port=5000)
