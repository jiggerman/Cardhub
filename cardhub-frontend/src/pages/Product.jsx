import React, { useEffect, useState } from 'react';
import { Link, useLocation, useParams } from 'react-router-dom';
import { cardsAPI } from '../services/cardsAPI';
import { useCart } from '../contexts/CartContext';
import Icon from '../components/ui/Icon';
import cardBack from '../Magic_card_back.webp';

const options = [
  { type: 'purchase', title: 'Купить сейчас', note: 'Есть на складе', badge: 'Быстрее всего' },
  { type: 'reservation', title: 'Предзаказ', note: 'Сообщим о поступлении', badge: 'Без оплаты' },
  { type: 'import', title: 'Заказать', note: 'Проверим у партнёра', badge: 'Цена уточняется' },
];

const Product = () => {
  const { cardId } = useParams();
  const location = useLocation();
  const { addToCart } = useCart();
  const [card, setCard] = useState(location.state?.card || null);
  const [loading, setLoading] = useState(!card);
  const [selected, setSelected] = useState(card?.inStock > 0 ? 'purchase' : 'reservation');
  const [quality, setQuality] = useState(card?.availableQualities?.[0] || 'NM');
  const [quantity, setQuantity] = useState(1);
  const [added, setAdded] = useState(false);
  const [imageFailed, setImageFailed] = useState(false);

  const purchaseOffers = (card?.offers || []).filter((offer) => offer.quantity > 0);
  const selectedOffer = purchaseOffers.filter((offer) => offer.quality === quality).sort((a, b) => a.price - b.price)[0];
  const selectedPrice = selected === 'purchase' ? selectedOffer?.price : null;
  const maxQuantity = selected === 'purchase' ? Math.min(4, selectedOffer?.quantity || 1) : 4;

  useEffect(() => {
    if (card) return;
    cardsAPI.getCard(cardId).then((value) => { setCard(value); setSelected(value.inStock > 0 ? 'purchase' : 'reservation'); setQuality(value.availableQualities?.[0] || 'NM'); }).catch(() => setCard(null)).finally(() => setLoading(false));
  }, [card, cardId]);

  if (loading) return <div className="full-state"><span className="loader" />Загружаем карту…</div>;
  if (!card) return <div className="full-state"><h1>Карта не найдена</h1><Link className="button button--primary" to="/catalog">Вернуться в каталог</Link></div>;

  const add = () => { addToCart(card, quality, quantity, selected); setAdded(true); setTimeout(() => setAdded(false), 2200); };
  const qualities = selected === 'purchase' && card.availableQualities?.length ? card.availableQualities : ['NM', 'SP', 'MP', 'HP'];

  return (
    <main className="section product-page">
      <div className="container breadcrumbs"><Link to="/catalog">Каталог</Link><Icon name="arrow" size={14} /><span>{card.setCode}</span><Icon name="arrow" size={14} /><span>{card.name}</span></div>
      <div className="container product-detail">
        <div className="product-art"><div className="product-art__halo" /><img src={!imageFailed && (card.imageUrlLarge || card.imageUrlNormal) ? (card.imageUrlLarge || card.imageUrlNormal) : cardBack} onError={() => setImageFailed(true)} alt={card.name} /></div>
        <div className="product-info">
          <div className="product-info__top"><span className="eyebrow">{card.setCode} · #{card.collectorNumber}</span><h1>{card.name}</h1><p>{card.type || card.setName}</p></div>
          <div className="fact-row"><div><span>Сет</span><strong>{card.setName || card.setCode}</strong></div><div><span>Цвет</span><strong>{card.color || '—'}</strong></div><div><span>На складе</span><strong>{card.inStock || 0} шт.</strong></div></div>
          <div className="buy-box">
            <div className="buy-options">{options.map((option) => { const disabled = option.type === 'purchase' && card.inStock === 0; return <button disabled={disabled} className={selected === option.type ? 'active' : ''} onClick={() => { setSelected(option.type); setQuantity(1); if (option.type === 'purchase' && !card.availableQualities.includes(quality)) setQuality(card.availableQualities[0] || 'NM'); }} key={option.type}><small>{option.badge}</small><strong>{option.title}</strong><span>{disabled ? 'Нет в наличии' : option.note}</span></button>; })}</div>
            <div className="buy-controls"><div><label>Состояние</label><div className="choice-row">{qualities.map((item) => <button key={item} className={quality === item ? 'active' : ''} onClick={() => { setQuality(item); setQuantity(1); }}>{item}</button>)}</div></div><div><label>Количество</label><div className="stepper"><button onClick={() => setQuantity(Math.max(1, quantity - 1))}><Icon name="minus" /></button><span>{quantity}</span><button onClick={() => setQuantity(Math.min(maxQuantity, quantity + 1))}><Icon name="plus" /></button></div></div></div>
            <div className="buy-total"><div><span>{selected === 'purchase' ? 'Итого' : 'Цена после подтверждения'}</span><strong>{selectedPrice ? `${(Number(selectedPrice) * quantity).toLocaleString('ru-RU')} ₽` : 'Уточняется'}</strong></div><button className="button button--primary" onClick={add} disabled={selected === 'purchase' && !selectedOffer}>{added ? <><Icon name="check" /> Добавлено</> : <><Icon name="cart" /> В корзину</>}</button></div>
          </div>
          <div className="trust-row"><span><Icon name="shield" /> Безопасная оплата</span><span><Icon name="package" /> Бережная упаковка</span></div>
        </div>
      </div>
    </main>
  );
};

export default Product;
