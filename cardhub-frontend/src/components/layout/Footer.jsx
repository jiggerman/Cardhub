import React from 'react';
import { Link } from 'react-router-dom';

const Footer = () => (
  <footer className="site-footer">
    <div className="container footer-grid">
      <div>
        <Link className="wordmark wordmark--footer" to="/">Card<span>Hub</span></Link>
        <p>Карты Magic: The Gathering из наличия и под заказ — с понятным статусом на каждом этапе.</p>
      </div>
      <div className="footer-links"><strong>Покупателям</strong><Link to="/catalog">Каталог</Link><Link to="/orders">История заказов</Link><Link to="/faq">Доставка и оплата</Link></div>
      <div className="footer-links"><strong>CardHub</strong><a href="mailto:support@cardhub.pw">support@cardhub.pw</a><a href="https://t.me/CardHubStore_bot" target="_blank" rel="noreferrer">Telegram-бот</a><span>Санкт-Петербург</span></div>
    </div>
    <div className="container footer-bottom"><span>© {new Date().getFullYear()} CardHub</span><span>Не является официальным продуктом Wizards of the Coast.</span></div>
  </footer>
);

export default Footer;
