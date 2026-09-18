import React, { useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import PageHero from '../components/ui/PageHero';
import SearchBar from '../components/ui/SearchBar';
import Icon from '../components/ui/Icon';
import CardGrid from '../features/cards/components/CardGrid';
import { useCart } from '../contexts/CartContext';

const Catalog = () => {
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const { addToCart } = useCart();
  const query = params.get('q') || '';
  const [view, setView] = useState('grid');
  const [filtersOpen, setFiltersOpen] = useState(false);

  const search = (value) => navigate(`/catalog?q=${encodeURIComponent(value)}`);

  return (
    <>
      <PageHero eyebrow="Каталог" title={query ? `Результаты для «${query}»` : 'Поиск по картам'} description="Найдите нужное издание и сразу выберите способ покупки.">
        <SearchBar onSearch={search} initialValue={query} />
      </PageHero>
      <main className="section catalog-page">
        <div className="container catalog-layout">
          <aside className={`filters-panel ${filtersOpen ? 'filters-panel--open' : ''}`}>
            <div className="filters-panel__head"><strong>Фильтры</strong><button onClick={() => setFiltersOpen(false)} aria-label="Закрыть фильтры"><Icon name="close" /></button></div>
            <label>Способ покупки<select defaultValue="all"><option value="all">Все варианты</option><option>В наличии</option><option>Предзаказ</option><option>Под заказ</option></select></label>
            <label>Цвет<select defaultValue="all"><option value="all">Любой цвет</option><option>Белый</option><option>Синий</option><option>Чёрный</option><option>Красный</option><option>Зелёный</option><option>Бесцветный</option></select></label>
            <label>Состояние<select defaultValue="all"><option value="all">Любое</option><option>NM</option><option>SP</option><option>MP</option><option>HP</option></select></label>
            <label>Цена<div className="range-fields"><input inputMode="numeric" placeholder="от" /><input inputMode="numeric" placeholder="до" /></div></label>
            <button className="button button--primary button--full">Применить</button>
            <button className="button button--ghost button--full">Сбросить</button>
          </aside>

          <div className="catalog-content">
            <div className="catalog-toolbar">
              <button className="button button--quiet mobile-filter" onClick={() => setFiltersOpen(true)}><Icon name="filter" /> Фильтры</button>
              <span className="catalog-toolbar__note">{query ? 'Показываем совпадения из каталога' : 'Введите название карты, чтобы начать поиск'}</span>
              <div className="view-toggle"><button className={view === 'grid' ? 'active' : ''} onClick={() => setView('grid')} aria-label="Сетка"><Icon name="grid" /></button><button className={view === 'list' ? 'active' : ''} onClick={() => setView('list')} aria-label="Список"><Icon name="list" /></button></div>
            </div>
            {query ? <CardGrid searchQuery={query} view={view} onAdd={(card) => addToCart(card, 'NM', 1, card.inStock > 0 ? 'purchase' : 'reservation')} /> : <div className="catalog-empty"><Icon name="search" size={36} /><h2>Найдите нужную карту</h2><p>Введите название карты на английском языке или выберите один из примеров.</p><div className="quick-links">{['Sol Ring', 'The One Ring', 'Lightning Bolt'].map((item) => <button key={item} onClick={() => search(item)}>{item}</button>)}</div></div>}
          </div>
        </div>
      </main>
    </>
  );
};

export default Catalog;
