import { API_BASE_URL, API_ENDPOINTS } from '../services/api';

export const cardsAPI = {
  async searchCards(cardName, page = 1, limit = 20) {
    try {
      const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.CARDS.SEARCH}${encodeURIComponent(cardName)}`);
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json();
      const [totalCount, cardsArray] = data;
      
      // Преобразуем данные с учётом JOIN
      const transformedCards = cardsArray.map(card => {

        console.log('Card inventory data:', {
          id: card[0],
          name: card[5],
          total_quantity: card[12],
          min_price: card[13],
          available_qualities: card[14]
        });
        
        return {
          id: card[0],
          color: card[1],
          setCode: card[2],
          setName: card[3],
          collectorNumber: card[4],
          name: card[5],
          type: card[6],
          imageUrlSmall: card[7],
          imageUrlNormal: card[8],
          imageUrlLarge: card[9],
          createdAt: card[10],
          updatedAt: card[11],
          // Данные из JOIN с инвентарём
          inStock: card[12] || 0, // total_quantity
          minPrice: card[13], // min_price
          availableQualities: card[14] || [], // available_qualities (может быть None)
          isPreorder: (card[12] || 0) === 0 // предзаказ если нет в наличии
        };
      });
      
      // Пагинация
      const startIndex = (page - 1) * limit;
      const endIndex = startIndex + limit;
      const paginatedCards = transformedCards.slice(startIndex, endIndex);

      return {
        total: totalCount,
        cards: paginatedCards,
        page,
        limit,
        hasMore: endIndex < totalCount
      };
    } catch (error) {
      console.error('Search cards error:', error);
      throw error;
    }
  }
};