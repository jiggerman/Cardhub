import React, { useEffect, useState } from 'react';
import { Link, NavLink, useLocation } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { useCart } from '../../contexts/CartContext';
import Icon from '../ui/Icon';

const Header = () => {
  const { user, isAuthenticated } = useAuth();
  const { getCartCount } = useCart();
  const [open, setOpen] = useState(false);
  const location = useLocation();

  useEffect(() => setOpen(false), [location.pathname]);
  const initials = (user?.username || user?.email || 'U').slice(0, 1).toUpperCase();

  return (
    <header className="site-header">
      <div className="container site-header__inner">
        <Link className="wordmark" to="/" aria-label="CardHub — на главную">
          <span className="wordmark__mark"><span /></span>
          <span>Card<span>Hub</span></span>
        </Link>

        <nav className={`main-nav ${open ? 'main-nav--open' : ''}`} aria-label="Основная навигация">
          <NavLink to="/catalog">Каталог</NavLink>
          <NavLink to="/orders">Мои заказы</NavLink>
          <NavLink to="/faq">Помощь</NavLink>
        </nav>

        <div className="header-actions">
          <Link className="icon-action" to="/catalog" aria-label="Поиск"><Icon name="search" /></Link>
          <Link className="icon-action icon-action--cart" to="/cart" aria-label={`Корзина, ${getCartCount()} товаров`}>
            <Icon name="cart" />
            {getCartCount() > 0 && <span className="cart-count">{getCartCount()}</span>}
          </Link>
          {isAuthenticated() ? (
            <Link className="profile-chip" to="/profile" aria-label="Профиль">
              <span>{initials}</span><span className="profile-chip__name">{user?.username || 'Профиль'}</span>
            </Link>
          ) : (
            <Link className="button button--small button--quiet auth-button" to="/auth">
              <Icon name="user" size={18} />Войти
            </Link>
          )}
          <button className="menu-button" onClick={() => setOpen((value) => !value)} aria-label="Открыть меню" aria-expanded={open}>
            <Icon name={open ? 'close' : 'menu'} />
          </button>
        </div>
      </div>
    </header>
  );
};

export default Header;
