import os
import sys

from flask import Blueprint, jsonify, request, current_app


from backend.src.db import Database


bp = Blueprint('cards', __name__)


@bp.route('/cards/search/<string:card_name>', methods=['GET'])
def search_cards(card_name):
    try:
        db: Database = current_app.db
        cards = db.search_card(card_name=card_name)
        return jsonify(cards)
    except Exception as e:
        return jsonify({'error': str(e)}), 500



