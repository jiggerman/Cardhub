import { useState, useEffect } from 'react';
import { cardsAPI } from '../../../services/cardsAPI';

export const useCardSearch = (query, page = 1) => {
  const [cards, setCards] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [total, setTotal] = useState(0);

  useEffect(() => {
    if (!query.trim()) {
      setCards([]);
      setTotal(0);
      return;
    }

    const searchCards = async () => {
      setLoading(true);
      setError(null);

      try {
        const response = await cardsAPI.searchCards(query, page);
        
        // ВСЕГДА заменяем карточки, а не добавляем
        setCards(response.cards);
        setTotal(response.total);
      } catch (err) {
        setError(err.message);
        setCards([]);
      } finally {
        setLoading(false);
      }
    };

    searchCards();
  }, [query, page]); // Зависимость от page и query

  return { cards, loading, error, total };
};