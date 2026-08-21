import os
import json
import logging
from flask import Flask, request
import requests

app = Flask(__name__)

NTFY_TOPIC = os.environ.get('NTFY_TOPIC')
NTFY_URL = f'https://ntfy.sh/{NTFY_TOPIC}'

logging.basicConfig(level=logging.INFO)

@app.route('/webhook', methods=['POST'])
def webhook():
    if not NTFY_TOPIC:
        logging.error("NTFY_TOPIC is not set")
        return "NTFY_TOPIC is not set", 500

    data = request.json
    logging.info(f"Received alert: {json.dumps(data)}")

    alerts = data.get('alerts', [])
    for alert in alerts:
        status = alert.get('status', 'unknown')
        annotations = alert.get('annotations', {})
        summary = annotations.get('summary', 'Alert')
        description = annotations.get('description', '')
        
        # Format the ntfy notification
        title = f"[{status.upper()}] {summary}"
        
        headers = {
            "Title": title,
            "Tags": "warning" if status.lower() == "firing" else "white_check_mark"
        }
        
        try:
            resp = requests.post(NTFY_URL, data=description.encode('utf-8'), headers=headers)
            resp.raise_for_status()
            logging.info(f"Sent to ntfy: {resp.status_code}")
        except Exception as e:
            logging.error(f"Error sending to ntfy: {e}")

    return "OK", 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
