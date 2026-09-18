import React, { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import SearchBar from '../components/ui/SearchBar';
import Icon from '../components/ui/Icon';
import { cardsAPI } from '../services/cardsAPI';
import cardBack from '../Magic_card_back.webp';

const showcase = [
  { name: 'The One Ring', hue: 'violet' },
  { name: 'Force of Will', hue: 'blue' },
  { name: 'Sheoldred', hue: 'rose' },
  { name: 'Ragavan', hue: 'amber' },
  { name: 'Polluted Delta', hue: 'teal' },
];

const Home = () => {
  const navigate = useNavigate();
  const [featuredCards, setFeaturedCards] = useState(showcase);
  const search = (query) => navigate(`/catalog?q=${encodeURIComponent(query)}`);

  useEffect(() => {
    let active = true;
    Promise.all(showcase.map(async (item) => {
      try {
        const result = await cardsAPI.searchCards(item.name, 1, 1);
        return { ...item, card: result.cards[0] || null };
      } catch {
        return item;
      }
    })).then((cards) => {
      if (active) setFeaturedCards(cards);
    });
    return () => { active = false; };
  }, []);

  const openCard = async (featuredCard) => {
    if (featuredCard.card) {
      navigate(`/cards/${featuredCard.card.id}`, { state: { card: featuredCard.card } });
      return;
    }
    try {
      const result = await cardsAPI.searchCards(featuredCard.name, 1, 1);
      const card = result.cards[0];
      if (card) {
        navigate(`/cards/${card.id}`, { state: { card } });
        return;
      }
    } catch {
      // Если каталог временно недоступен, оставляем пользователю страницу поиска.
    }
    search(featuredCard.name);
  };

  return (
    <>
      <section className="home-hero">
        <div className="home-hero__noise" />
        <div className="container home-hero__inner">
          <div className="home-hero__copy">
            <span className="eyebrow"><Icon name="sparkle" size={16} /> MTG marketplace · Санкт-Петербург</span>
            <h1>Найдите ту самую <em>карту.</em></h1>
            <p>Быстрый поиск по каталогу, честные остатки и три понятных способа получить карту — из наличия, в предзаказ или через партнёра.</p>
            <SearchBar onSearch={search} large />
            <div className="search-hints"><span>Популярное:</span>{['The One Ring', 'Sol Ring', 'Sheoldred'].map((name) => <button key={name} onClick={() => search(name)}>{name}</button>)}</div>
          </div>
          <div className="card-fan">
            {featuredCards.map((item, index) => <button type="button" className={`fan-card fan-card--${item.hue}`} key={item.name} style={{ '--i': index }} onClick={() => openCard(item)} aria-label={`Открыть карту ${item.name}`}><img src={item.card?.imageUrlNormal || cardBack} alt={item.card ? `Обложка карты ${item.name}` : ''} onError={(event) => { event.currentTarget.src = cardBack; }} /><span>{item.name}</span></button>)}
          </div>
        </div>
      </section>

      <section className="section section--steps">
        <div className="container">
          <div className="section-heading"><span className="eyebrow">Покупка карт</span><h2>Как оформить заказ</h2><p>Найдите нужную карту, добавьте её в корзину и укажите данные для доставки.</p></div>
          <div className="feature-grid">
            <article><span className="feature-index">01</span><Icon name="search" size={28} /><h3>Найдите карту</h3><p>Введите название карты. В результатах поиска будут указаны доступные издания, цены и остатки.</p></article>
            <article><span className="feature-index">02</span><Icon name="package" size={28} /><h3>Добавьте в корзину</h3><p>Выберите состояние и количество. Если карты нет в наличии, оформите предзаказ или заказ у партнёра.</p></article>
            <article><span className="feature-index">03</span><Icon name="clock" size={28} /><h3>Оформите заказ</h3><p>Укажите контакты и способ доставки. Текущий статус заказа отображается в личном кабинете.</p></article>
          </div>
        </div>
      </section>

      <section className="section">
        <div className="container service-banner">
          <div><span className="eyebrow">Нет в наличии</span><h2>Ищете конкретную карту?</h2><p>Найдите её в каталоге и оформите предзаказ или заказ у партнёра.</p></div>
          <Link to="/catalog" className="button button--light">Перейти в каталог <Icon name="arrow" size={18} /></Link>
        </div>
      </section>
    </>
  );
};

export default Home;
