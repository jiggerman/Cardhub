import requests

class Scryfall:
    def __init__(self, url="https://api.scryfall.com/"):
        self.url = url

    def search_card(self, card_name):
        end_point = f"cards/search?q={card_name}"
        request = requests.get(self.url + end_point)

        if request.status_code == 200:
            return request.json()

        return []

    def parse_defaulte_database(self):
        pass