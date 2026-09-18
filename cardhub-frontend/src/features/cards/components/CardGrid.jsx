import React, { useEffect, useState } from 'react';
import { useCardSearch } from '../hooks/useCardSearch';
import Card from './Card';

const CardGrid = ({ searchQuery, filters, view = 'grid', onAdd }) => {
  const [page, setPage] = useState(1);
  const { cards, loading, error, total } = useCardSearch(searchQuery, page, filters);
  useEffect(() => setPage(1), [searchQuery]);

  if (loading) return <div className="catalog-state"><span className="loader" /><strong>Ищем карты…</strong><p>Проверяем каталог и остатки.</p></div>;
  if (error) return <div className="catalog-state catalog-state--error"><strong>Каталог временно недоступен</strong><p>{error}</p></div>;
  if (!cards.length) return <div className="catalog-state"><strong>Ничего не нашли</strong><p>Попробуйте английское название карты или код сета.</p></div>;

  const pages = Math.max(1, Math.ceil(total / 20));
  return (
    <>
      <div className={`products products--${view}`}>{cards.map((card) => <Card key={card.id} card={card} view={view} onAdd={onAdd} />)}</div>
      {pages > 1 && <div className="pagination"><button disabled={page === 1} onClick={() => setPage(page - 1)}>Назад</button><span>{page} / {pages}</span><button disabled={page === pages} onClick={() => setPage(page + 1)}>Дальше</button></div>}
    </>
  );
};

export default CardGrid;
