import { API_BASE_URL, API_ENDPOINTS } from '../services/api';

export const cardsAPI = {
  async searchCards(cardName, page = 1, limit = 20) {
    try {
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.CARDS.SEARCH}${encodeURIComponent(cardName)}`);

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      const cardsArray = data.cards || [];

      const transformedCards = cardsArray.map(card => ({
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
        // Данные из инвентаря (агрегированы на бэкенде)
        inStock: card.in_stock || 0,
        minPrice: card.min_price,
        availableQualities: card.available_qualities || [],
        isPreorder: (card.in_stock || 0) === 0
      }));

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
  }
};
