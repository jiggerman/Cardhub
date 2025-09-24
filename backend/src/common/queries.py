TABLE_CREATE = {
    "card_table": """CREATE TABLE IF NOT EXISTS cards (
        id SERIAL PRIMARY KEY,
        color VARCHAR(15),
        set_code VARCHAR(15) NOT NULL,
        set_name VARCHAR(50),
        collector_number INTEGER NOT NULL,
        name VARCHAR(50) NOT NULL,
        lang VARCHAR(15) NOT NULL,
        quality VARCHAR(20),
        foil BOOLEAN,
        quantity INTEGER NOT NULL DEFAULT 0,
        price DECIMAL(10,2),
        owner VARCHAR(50),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );""",
}

