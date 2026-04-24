from flask import Flask, jsonify, request
from flask_cors import CORS
from datetime import datetime
import json
import os

app = Flask(__name__)
CORS(app)

DATA_FILE = 'data.json'

# Initialize data file
def init_data():
    if not os.path.exists(DATA_FILE):
        data = {
            'users': [],
            'posts': [],
            'keywords': [],
            'comments': []
        }
        save_data(data)

def load_data():
    try:
        with open(DATA_FILE, 'r') as f:
            return json.load(f)
    except:
        return {'users': [], 'posts': [], 'keywords': [], 'comments': []}

def save_data(data):
    with open(DATA_FILE, 'w') as f:
        json.dump(data, f, indent=2)

# Today's keyword
KEYWORDS = [
    ("이별", "Farewell"), ("행복", "Happiness"), ("청춘", "Youth"),
    ("미래", "Future"), ("고독", "Solitude"), ("기억", "Memory"),
    ("용기", "Courage"), ("성찰", "Reflection"), ("성장", "Growth"),
    ("꿈", "Dream"), ("여정", "Journey"), ("침묵", "Silence"),
]

@app.route('/')
def index():
    return jsonify({"message": "WriteHabit API", "version": "1.0"})

@app.route('/api/keyword/today')
def today_keyword():
    today = datetime.now()
    idx = (today.year * 10000 + today.month * 100 + today.day) % len(KEYWORDS)
    ko, en = KEYWORDS[idx]
    return jsonify({
        "keyword": ko,
        "english": en,
        "number": idx + 1,
        "date": today.strftime("%Y-%m-%d")
    })

@app.route('/api/posts', methods=['GET'])
def get_posts():
    data = load_data()
    return jsonify(data['posts'])

@app.route('/api/posts', methods=['POST'])
def create_post():
    data = load_data()
    new_post = request.get_json()
    new_post['id'] = len(data['posts']) + 1
    new_post['created_at'] = datetime.now().isoformat()
    data['posts'].insert(0, new_post)
    save_data(data)
    return jsonify({"success": True, "id": new_post['id']})

@app.route('/api/posts/<int:post_id>/comments', methods=['GET'])
def get_comments(post_id):
    data = load_data()
    comments = [c for c in data['comments'] if c['post_id'] == post_id]
    return jsonify(comments)

@app.route('/api/posts/<int:post_id>/comments', methods=['POST'])
def add_comment(post_id):
    data = load_data()
    new_comment = request.get_json()
    new_comment['id'] = len(data['comments']) + 1
    new_comment['post_id'] = post_id
    new_comment['created_at'] = datetime.now().isoformat()
    data['comments'].append(new_comment)
    save_data(data)
    return jsonify({"success": True, "id": new_comment['id']})

@app.route('/api/auth/login', methods=['POST'])
def login():
    data = request.get_json()
    return jsonify({
        "success": True,
        "user": {
            "id": 1,
            "email": data.get('email'),
            "name": "글쓰기 민",
            "handle": "writer_min",
            "initial": "민"
        }
    })

if __name__ == '__main__':
    init_data()
    app.run(debug=True, port=5000)
