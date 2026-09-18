import React, { useEffect, useMemo, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import PageHero from '../components/ui/PageHero';
import SearchBar from '../components/ui/SearchBar';
import Icon from '../components/ui/Icon';
import CardGrid from '../features/cards/components/CardGrid';
import { useCart } from '../contexts/CartContext';

const FILTER_KEYS = ['in_stock', 'color', 'quality', 'min_price', 'max_price'];
const EMPTY_FILTERS = { in_stock: '', color: '', quality: '', min_price: '', max_price: '' };

const readFilters = (params) => FILTER_KEYS.reduce((filters, key) => ({
  ...filters,
  [key]: params.get(key) || '',
}), {});

const Catalog = () => {
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const { addToCart } = useCart();
  const query = params.get('q') || '';
  const [view, setView] = useState('grid');
  const [filtersOpen, setFiltersOpen] = useState(false);
  const paramsKey = params.toString();
  const appliedFilters = useMemo(
    () => readFilters(new URLSearchParams(paramsKey)),
    [paramsKey]
  );
  const [draftFilters, setDraftFilters] = useState(appliedFilters);

  useEffect(() => setDraftFilters(appliedFilters), [appliedFilters]);

  const updateDraft = (key, value) => {
    setDraftFilters((current) => ({ ...current, [key]: value }));
  };

  const search = (value) => {
    const next = new URLSearchParams(params);
    next.set('q', value);
    navigate(`/catalog?${next.toString()}`);
  };

  const applyFilters = (event) => {
    event.preventDefault();
    const next = new URLSearchParams(params);
    FILTER_KEYS.forEach((key) => {
      if (draftFilters[key]) next.set(key, draftFilters[key]);
      else next.delete(key);
    });
    navigate(`/catalog?${next.toString()}`);
    setFiltersOpen(false);
  };

  const resetFilters = () => {
    const next = new URLSearchParams(params);
    FILTER_KEYS.forEach((key) => next.delete(key));
    setDraftFilters(EMPTY_FILTERS);
    navigate(`/catalog?${next.toString()}`);
    setFiltersOpen(false);
  };

  return (
    <>
      <PageHero eyebrow="Каталог" title={query ? `Результаты для «${query}»` : 'Поиск по картам'} description="Найдите нужное издание и сразу выберите способ покупки.">
        <SearchBar onSearch={search} initialValue={query} />
      </PageHero>
      <main className="section catalog-page">
        <div className="container catalog-layout">
          <form className={`filters-panel ${filtersOpen ? 'filters-panel--open' : ''}`} onSubmit={applyFilters}>
            <div className="filters-panel__head"><strong>Фильтры</strong><button type="button" onClick={() => setFiltersOpen(false)} aria-label="Закрыть фильтры"><Icon name="close" /></button></div>
            <label>Наличие<select value={draftFilters.in_stock} onChange={(event) => updateDraft('in_stock', event.target.value)}><option value="">Все карты</option><option value="true">В наличии</option></select></label>
            <label>Цвет<select value={draftFilters.color} onChange={(event) => updateDraft('color', event.target.value)}><option value="">Любой цвет</option><option value="White">Белый</option><option value="Blue">Синий</option><option value="Black">Чёрный</option><option value="Red">Красный</option><option value="Green">Зелёный</option><option value="Multicolor">Многоцветный</option><option value="Colorless">Бесцветный</option></select></label>
            <label>Состояние<select value={draftFilters.quality} onChange={(event) => updateDraft('quality', event.target.value)}><option value="">Любое</option><option value="NM">NM</option><option value="SP">SP</option><option value="MP">MP</option><option value="HP">HP</option><option value="DM">DM</option></select></label>
            <label>Цена<div className="range-fields"><input type="number" min="0" step="0.01" value={draftFilters.min_price} onChange={(event) => updateDraft('min_price', event.target.value)} placeholder="от" /><input type="number" min="0" step="0.01" value={draftFilters.max_price} onChange={(event) => updateDraft('max_price', event.target.value)} placeholder="до" /></div></label>
            <button type="submit" className="button button--primary button--full">Применить</button>
            <button type="button" className="button button--ghost button--full" onClick={resetFilters}>Сбросить</button>
          </form>

          <div className="catalog-content">
            <div className="catalog-toolbar">
              <button className="button button--quiet mobile-filter" onClick={() => setFiltersOpen(true)}><Icon name="filter" /> Фильтры</button>
              <span className="catalog-toolbar__note">{query ? 'Показываем совпадения из каталога' : 'Введите название карты, чтобы начать поиск'}</span>
              <div className="view-toggle"><button className={view === 'grid' ? 'active' : ''} onClick={() => setView('grid')} aria-label="Сетка"><Icon name="grid" /></button><button className={view === 'list' ? 'active' : ''} onClick={() => setView('list')} aria-label="Список"><Icon name="list" /></button></div>
            </div>
            {query ? <CardGrid key={paramsKey} searchQuery={query} filters={appliedFilters} view={view} onAdd={(card) => addToCart(card, 'NM', 1, card.inStock > 0 ? 'purchase' : 'reservation')} /> : <div className="catalog-empty"><Icon name="search" size={36} /><h2>Найдите нужную карту</h2><p>Введите название карты на английском языке или выберите один из примеров.</p><div className="quick-links">{['Sol Ring', 'The One Ring', 'Lightning Bolt'].map((item) => <button key={item} onClick={() => search(item)}>{item}</button>)}</div></div>}
          </div>
        </div>
      </main>
    </>
  );
};

export default Catalog;
