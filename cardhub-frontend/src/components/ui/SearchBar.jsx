import React, { useEffect, useState } from 'react';
import Icon from './Icon';

const SearchBar = ({ onSearch, initialValue = '', large = false, placeholder = 'Название карты, сет или номер…' }) => {
  const [query, setQuery] = useState(initialValue);
  useEffect(() => setQuery(initialValue), [initialValue]);

  const submit = (event) => {
    event.preventDefault();
    if (query.trim()) onSearch(query.trim());
  };

  return (
    <form className={`search-bar ${large ? 'search-bar--large' : ''}`} onSubmit={submit} role="search">
      <Icon name="search" size={large ? 24 : 20} />
      <input aria-label="Поиск карт" value={query} onChange={(event) => setQuery(event.target.value)} placeholder={placeholder} />
      {query && <button type="button" className="search-bar__clear" onClick={() => setQuery('')} aria-label="Очистить поиск"><Icon name="close" size={18} /></button>}
      <button type="submit" className="button button--primary search-bar__submit">Найти</button>
    </form>
  );
};

export default SearchBar;
