class User:
    def __init__(self, data):
        self.id, self.email, self.password_hash, self.username, self.role, self.email_verified, \
            self.email_verification_token, self.telegram_chat_id, self.telegram_username, self.telegram_verified, \
            self.shipping_address, self.created_at, self.updated_at = data
        self.data = [dat for i, dat in enumerate(data) if i != 2]

    def __str__(self):
        return f"{self.data}"
