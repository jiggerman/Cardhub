import React, { useEffect, useRef, useState } from 'react';
import { cardsAPI } from '../../services/cardsAPI';
import Icon from './Icon';

const SearchBar = ({ onSearch, initialValue = '', large = false, placeholder = 'Название карты, сет или номер…' }) => {
  const [query, setQuery] = useState(initialValue);
  const [suggestions, setSuggestions] = useState([]);
  const [open, setOpen] = useState(false);
  const [activeIndex, setActiveIndex] = useState(-1);
  const rootRef = useRef(null);
  const inputRef = useRef(null);
  const skipNextSuggestionRef = useRef(false);
  useEffect(() => setQuery(initialValue), [initialValue]);

  useEffect(() => {
    const value = query.trim();
    if (skipNextSuggestionRef.current) {
      skipNextSuggestionRef.current = false;
      return undefined;
    }
    if (value.length < 2) {
      setSuggestions([]);
      setOpen(false);
      return undefined;
    }

    const controller = new AbortController();
    const timer = window.setTimeout(async () => {
      try {
        const items = await cardsAPI.suggestCards(value, controller.signal);
        setSuggestions(items);
        setActiveIndex(-1);
        setOpen(items.length > 0 && document.activeElement === inputRef.current);
      } catch (error) {
        if (error.name !== 'AbortError') setOpen(false);
      }
    }, 250);
    return () => {
      window.clearTimeout(timer);
      controller.abort();
    };
  }, [query]);

  useEffect(() => {
    const closeOnOutsideClick = (event) => {
      if (!rootRef.current?.contains(event.target)) setOpen(false);
    };
    document.addEventListener('mousedown', closeOnOutsideClick);
    return () => document.removeEventListener('mousedown', closeOnOutsideClick);
  }, []);

  const chooseSuggestion = (value) => {
    skipNextSuggestionRef.current = true;
    setQuery(value);
    setOpen(false);
    onSearch(value);
  };

  const submit = (event) => {
    event.preventDefault();
    if (query.trim()) onSearch(query.trim());
    setOpen(false);
  };

  const onKeyDown = (event) => {
    if (!open || !suggestions.length) return;
    if (event.key === 'ArrowDown') {
      event.preventDefault();
      setActiveIndex((index) => (index + 1) % suggestions.length);
    } else if (event.key === 'ArrowUp') {
      event.preventDefault();
      setActiveIndex((index) => (index <= 0 ? suggestions.length - 1 : index - 1));
    } else if (event.key === 'Enter' && activeIndex >= 0) {
      event.preventDefault();
      chooseSuggestion(suggestions[activeIndex]);
    } else if (event.key === 'Escape') {
      setOpen(false);
    }
  };

  const clear = () => {
    setQuery('');
    setSuggestions([]);
    setOpen(false);
  };

  return (
    <form ref={rootRef} className={`search-bar ${large ? 'search-bar--large' : ''}`} onSubmit={submit} role="search">
      <Icon name="search" size={large ? 24 : 20} />
      <input
        ref={inputRef}
        aria-label="Поиск карт"
        aria-autocomplete="list"
        aria-controls="card-search-suggestions"
        aria-expanded={open}
        role="combobox"
        autoComplete="off"
        value={query}
        onChange={(event) => setQuery(event.target.value)}
        onFocus={() => suggestions.length && setOpen(true)}
        onKeyDown={onKeyDown}
        placeholder={placeholder}
      />
      {query && <button type="button" className="search-bar__clear" onClick={clear} aria-label="Очистить поиск"><Icon name="close" size={18} /></button>}
      <button type="submit" className="button button--primary search-bar__submit">Найти</button>
      {open && <ul id="card-search-suggestions" className="search-suggestions" role="listbox">
        {suggestions.map((suggestion, index) => <li key={suggestion} role="option" aria-selected={index === activeIndex}>
          <button
            type="button"
            className={index === activeIndex ? 'active' : ''}
            onMouseDown={(event) => event.preventDefault()}
            onClick={() => chooseSuggestion(suggestion)}
          >
            <Icon name="search" size={16} />
            <span>{suggestion}</span>
          </button>
        </li>)}
      </ul>}
    </form>
  );
};

export default SearchBar;
