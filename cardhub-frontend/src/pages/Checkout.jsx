import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { useCart } from '../contexts/CartContext';
import { useAuth } from '../contexts/AuthContext';
import PageHero from '../components/ui/PageHero';
import Icon from '../components/ui/Icon';

const Checkout = () => {
  const { cartItems, getCartTotal } = useCart();
  const { user } = useAuth();
  const [delivery, setDelivery] = useState('cdek');
  const [payment, setPayment] = useState('card');
  const [submitted, setSubmitted] = useState(false);

  if (!cartItems.length) return <div className="full-state"><h1>Оформлять пока нечего</h1><p>Корзина пуста.</p><Link className="button button--primary" to="/catalog">В каталог</Link></div>;
  if (submitted) return <div className="full-state full-state--success"><div className="success-mark"><Icon name="check" size={36} /></div><h1>Данные готовы</h1><p>Интерфейс оформления подготовлен. Отправка заказа будет включена после расширения API заказов.</p><Link className="button button--primary" to="/orders">К моим заказам</Link></div>;

  return (
    <>
      <PageHero eyebrow="Шаг 2 из 2" title="Оформление заказа" description="Проверьте контакты и выберите удобный способ получения." />
      <main className="section"><div className="container checkout-layout">
        <form className="checkout-form" onSubmit={(event) => { event.preventDefault(); setSubmitted(true); }}>
          <section className="checkout-section"><div className="checkout-section__title"><span>1</span><div><h2>Контактные данные</h2><p>Для подтверждения и уведомлений.</p></div></div><div className="form-grid"><label>Имя<input defaultValue={user?.username || ''} required placeholder="Ваше имя" /></label><label>Email<input type="email" defaultValue={user?.email || ''} required placeholder="you@example.com" /></label><label>Телефон<input type="tel" required placeholder="+7 999 000-00-00" /></label><label>Telegram<input defaultValue={user?.telegram_username ? `@${user.telegram_username}` : ''} placeholder="@username" /></label></div></section>
          <section className="checkout-section"><div className="checkout-section__title"><span>2</span><div><h2>Доставка</h2><p>Стоимость появится после выбора города.</p></div></div><div className="option-cards">{[['cdek','СДЭК','До пункта выдачи'],['post','Почта России','В любое отделение'],['pickup','Самовывоз','Санкт-Петербург']].map(([value,title,note]) => <label className={delivery === value ? 'active' : ''} key={value}><input type="radio" name="delivery" value={value} checked={delivery === value} onChange={() => setDelivery(value)} /><Icon name={value === 'pickup' ? 'location' : 'package'} /><strong>{title}</strong><span>{note}</span></label>)}</div><label className="wide-field">Город и адрес<textarea required placeholder="Город, улица, дом, квартира" /></label></section>
          <section className="checkout-section"><div className="checkout-section__title"><span>3</span><div><h2>Оплата</h2><p>После подтверждения состава заказа.</p></div></div><div className="option-cards option-cards--payment">{[['card','Банковская карта'],['sbp','СБП'],['balance','Баланс аккаунта']].map(([value,title]) => <label className={payment === value ? 'active' : ''} key={value}><input type="radio" name="payment" checked={payment === value} onChange={() => setPayment(value)} /><strong>{title}</strong></label>)}</div></section>
          <label className="consent"><input type="checkbox" required /><span>Я принимаю условия <Link to="/faq#offer">публичной оферты</Link> и подтверждаю контактные данные.</span></label>
          <button className="button button--primary button--large button--full">Подтвердить заказ</button>
        </form>
        <aside className="checkout-summary"><h2>Ваш заказ</h2>{cartItems.map((item) => <div className="checkout-summary__item" key={`${item.card.id}-${item.orderType}`}><div><strong>{item.card.name}</strong><span>{item.quantity} × {item.quality}</span></div><strong>{item.card.minPrice ? `${(Number(item.card.minPrice) * item.quantity).toLocaleString('ru-RU')} ₽` : 'Уточняется'}</strong></div>)}<div className="summary-total"><span>Итого</span><strong>{getCartTotal().toLocaleString('ru-RU')} ₽</strong></div><p><Icon name="info" size={16} /> Доставка и заказные позиции рассчитываются отдельно.</p></aside>
      </div></main>
    </>
  );
};

export default Checkout;
