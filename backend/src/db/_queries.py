TABLE_CREATE = {
    "cards": """CREATE TABLE IF NOT EXISTS cards (
        id SERIAL PRIMARY KEY,
        color VARCHAR(15),
        set_code VARCHAR(30) NOT NULL,
        set_name VARCHAR(50),
        collector_number VARCHAR(50) NOT NULL,
        name VARCHAR(100) NOT NULL,
        card_type VARCHAR(255),
        image_url_small VARCHAR(255),
        image_url_normal VARCHAR(255),
        image_url_large VARCHAR(255),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    )""",

    "users": """CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        username VARCHAR(50) UNIQUE NOT NULL,
        role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('user', 'admin', 'moderator')),
        email_verified BOOLEAN DEFAULT FALSE,
        email_verification_token VARCHAR(255),
        telegram_chat_id BIGINT, 
        telegram_username VARCHAR(255),
        telegram_verified BOOLEAN DEFAULT FALSE,
        shipping_address JSONB,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    """,

    "card_inventory": """CREATE TABLE IF NOT EXISTS card_inventory (
        id SERIAL PRIMARY KEY,
        card_id INTEGER REFERENCES cards(id) ON DELETE CASCADE,
        lang VARCHAR(15),
        quality VARCHAR(20) CHECK (quality IN ('NM', 'SP', 'HP', 'MP', 'DM', 'NM-', 'SP+', 'SP-')),
        foil BOOLEAN DEFAULT FALSE,
        quantity INTEGER NOT NULL DEFAULT 0,
        price DECIMAL(10,2) NOT NULL,
        owner VARCHAR(50),
        owner_id INTEGER REFERENCES users(id),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    )
    """,

    "orders": """CREATE TABLE IF NOT EXISTS orders (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) NOT NULL,
        status VARCHAR(20) DEFAULT 'pending',
        total_amount DECIMAL(10, 2) NOT NULL,
        shipping_address JSONB,
        tracking_number VARCHAR(100),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    """,

    "order_items": """CREATE TABLE IF NOT EXISTS order_items (
        id SERIAL PRIMARY KEY,
        order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
        card_inventory_id INTEGER REFERENCES card_inventory(id) ON DELETE CASCADE,
        quantity INTEGER NOT NULL,
        unit_price DECIMAL(10,2) NOT NULL,
        subtotal DECIMAL(10,2) NOT NULL
    )
    """,

    "cart_items": """CREATE TABLE IF NOT EXISTS cart_items (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        card_inventory_id INTEGER REFERENCES card_inventory(id) ON DELETE CASCADE,
        quantity INTEGER DEFAULT 1,
        added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, card_inventory_id)
    )
    """,

    "card_requests": """CREATE TABLE IF NOT EXISTS card_requests (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        card_inventory_id INTEGER REFERENCES cards(id) ON DELETE CASCADE,
        max_price DECIMAL(10,2),
        status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'fulfilled', 'closed')),
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    """,

    "password_resets": """CREATE TABLE IF NOT EXISTS password_resets (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        token VARCHAR(100) NOT NULL,
        expires_at TIMESTAMP NOT NULL,
        used BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    """
}

