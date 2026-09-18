import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import magicCardBack from '../../../Magic_card_back.webp';
import Icon from '../../../components/ui/Icon';

const Card = ({ card, view = 'grid', onAdd }) => {
  const [imageFailed, setImageFailed] = useState(false);
  const image = !imageFailed && card.imageUrlNormal ? card.imageUrlNormal : magicCardBack;
  const status = card.inStock > 0 ? 'В наличии' : 'Предзаказ';

  return (
    <article className={`product-card product-card--${view}`}>
      <Link className="product-card__visual" to={`/cards/${card.id}`} state={{ card }}>
        <img src={image} alt={card.name} onError={() => setImageFailed(true)} loading="lazy" />
        <span className={`status-pill ${card.inStock > 0 ? 'status-pill--stock' : 'status-pill--preorder'}`}>{status}</span>
      </Link>
      <div className="product-card__body">
        <div className="product-card__set"><span>{card.setCode || 'MTG'}</span><span>#{card.collectorNumber || '—'}</span></div>
        <Link className="product-card__title" to={`/cards/${card.id}`} state={{ card }}>{card.name}</Link>
        <p>{card.type || card.setName || 'Magic: The Gathering'}</p>
        <div className="product-card__meta">
          <div><span>от</span><strong>{card.minPrice ? `${Number(card.minPrice).toLocaleString('ru-RU')} ₽` : 'по запросу'}</strong></div>
          <button className="round-add" onClick={() => onAdd?.(card)} aria-label={`Добавить ${card.name} в корзину`}><Icon name="plus" /></button>
        </div>
      </div>
    </article>
  );
};

export default Card;
