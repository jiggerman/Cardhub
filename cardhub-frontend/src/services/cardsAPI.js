import { API_BASE_URL, API_ENDPOINTS } from '../services/api';

export const cardsAPI = {
  async getCard(cardId) {
    const response = await fetch(`${API_BASE_URL}/api/card/${cardId}`);
    if (!response.ok) throw new Error('Не удалось загрузить карту');
    const card = await response.json();
    return transformCard(card);
  },
  async searchCards(cardName, page = 1, limit = 20) {
    try {
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.CARDS.SEARCH}${encodeURIComponent(cardName)}`);

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      const cardsArray = data.cards || [];

      const transformedCards = cardsArray.map(transformCard);

      // Бэкенд пока не поддерживает серверную пагинацию — режем на клиенте
      const total = data.counter || 0;
      const startIndex = (page - 1) * limit;
      const endIndex = startIndex + limit;
      const paginatedCards = transformedCards.slice(startIndex, endIndex);

      return {
        total,
        cards: paginatedCards,
        page,
        limit,
        hasMore: endIndex < total
      };
    } catch (error) {
      console.error('Search cards error:', error);
      throw error;
    }
  },
  async suggestCards(query, signal) {
    const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.CARDS.SEARCH}${encodeURIComponent(query)}`, { signal });
    if (!response.ok) throw new Error('Не удалось загрузить подсказки');
    const data = await response.json();
    return [...new Set((data.cards || []).map((card) => card.name))].slice(0, 8);
  }
};

function transformCard(card) {
  const offers = (card.offers || []).map((offer) => ({
    id: offer.id,
    quality: offer.quality,
    language: offer.lang,
    foil: offer.foil,
    quantity: offer.quantity,
    price: Number(offer.price),
  }));
  return {
    id: card.id,
    color: card.color,
    setCode: card.set_code,
    setName: card.set_name,
    collectorNumber: card.collection_number,
    name: card.name,
    type: card.card_type,
    imageUrlSmall: card.image_url_small,
    imageUrlNormal: card.image_url_normal,
    imageUrlLarge: card.image_url_large,
    createdAt: card.created_at,
    updatedAt: card.updated_at,
    inStock: card.in_stock || 0,
    minPrice: card.min_price,
    availableQualities: card.available_qualities || [],
    offers,
    isPreorder: (card.in_stock || 0) === 0,
  };
}
