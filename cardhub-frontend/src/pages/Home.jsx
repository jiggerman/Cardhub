import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import SearchBar from '../components/ui/SearchBar';
import Icon from '../components/ui/Icon';
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
  const search = (query) => navigate(`/catalog?q=${encodeURIComponent(query)}`);

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
          <div className="card-fan" aria-hidden="true">
            {showcase.map((card, index) => <div className={`fan-card fan-card--${card.hue}`} key={card.name} style={{ '--i': index }}><img src={cardBack} alt="" /><span>{card.name}</span></div>)}
          </div>
        </div>
        <div className="hero-metrics container">
          <div><strong>18 000+</strong><span>карт в каталоге</span></div>
          <div><strong>3 формата</strong><span>покупка, заказ, предзаказ</span></div>
          <div><strong>1–2 дня</strong><span>на сборку из наличия</span></div>
        </div>
      </section>

      <section className="section section--steps">
        <div className="container">
          <div className="section-heading"><span className="eyebrow">Как это работает</span><h2>От запроса до колоды</h2><p>Мы убрали лишние шаги и показали главное прямо в каталоге.</p></div>
          <div className="feature-grid">
            <article><span className="feature-index">01</span><Icon name="search" size={28} /><h3>Ищите точно</h3><p>Название, сет и номер коллекции — как в Scryfall, но сразу с локальными остатками и ценой.</p></article>
            <article><span className="feature-index">02</span><Icon name="package" size={28} /><h3>Выберите способ</h3><p>Заберите карту из наличия, забронируйте пополнение или закажите её у партнёра.</p></article>
            <article><span className="feature-index">03</span><Icon name="clock" size={28} /><h3>Следите за статусом</h3><p>Этапы сверки, сборки и доставки собраны в личном кабинете без писем и таблиц.</p></article>
          </div>
        </div>
      </section>

      <section className="section">
        <div className="container service-banner">
          <div><span className="eyebrow">Подбор карт</span><h2>Не нашли нужное издание?</h2><p>Оставьте заказ — мы проверим предложения партнёров и свяжемся до оплаты.</p></div>
          <Link to="/catalog" className="button button--light">Перейти в каталог <Icon name="arrow" size={18} /></Link>
        </div>
      </section>
    </>
  );
};

export default Home;
