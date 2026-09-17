import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { useCart } from '../contexts/CartContext';
import { useAuth } from '../contexts/AuthContext';
import { ordersAPI } from '../services/ordersAPI';
import PageHero from '../components/ui/PageHero';
import Icon from '../components/ui/Icon';

const Checkout = () => {
  const { cartItems, getCartTotal, clearCart, removeOrderTypes } = useCart();
  const { user } = useAuth();
  const savedAddress = typeof user?.shipping_address === 'string' ? user.shipping_address : user?.shipping_address?.address || '';
  const [delivery, setDelivery] = useState('cdek');
  const [payment, setPayment] = useState('card');
  const [form, setForm] = useState({
    name: user?.username || '', email: user?.email || '', phone: '',
    telegram: user?.telegram_username ? `@${user.telegram_username}` : '', address: savedAddress,
  });
  const [createdOrders, setCreatedOrders] = useState([]);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [partialError, setPartialError] = useState('');

  const change = (event) => setForm((value) => ({ ...value, [event.target.name]: event.target.value }));
  const submit = async (event) => {
    event.preventDefault(); setError(''); setSubmitting(true);
    const orders = [];
    const completedTypes = [];
    try {
      const grouped = cartItems.reduce((result, item) => {
        (result[item.orderType] ||= []).push(item); return result;
      }, {});
      for (const [orderType, items] of Object.entries(grouped)) {
        if (orderType === 'purchase' && items.some((item) => !item.offerId)) {
          throw new Error('Одна из складских позиций устарела. Удалите её из корзины и добавьте заново.');
        }
        orders.push(await ordersAPI.create(orderType, items, delivery, { ...form, payment }));
        completedTypes.push(orderType);
      }
      setCreatedOrders(orders); clearCart();
    } catch (requestError) {
      if (orders.length) {
        removeOrderTypes(completedTypes); setCreatedOrders(orders);
        setPartialError(`Часть заказа создана, но остальные позиции не отправлены: ${requestError.message}`);
      } else setError(requestError.message);
    } finally { setSubmitting(false); }
  };

  if (createdOrders.length) return <div className="full-state full-state--success"><div className="success-mark"><Icon name={partialError ? 'info' : 'check'} size={36} /></div><h1>{partialError ? 'Заказ создан частично' : 'Заказ оформлен'}</h1><p>{partialError || `Создано заказов: ${createdOrders.length}. Номера: ${createdOrders.map((order) => `#${order.id}`).join(', ')}.`}</p><Link className="button button--primary" to="/orders">К моим заказам</Link>{partialError && <Link className="button button--quiet" to="/cart">Вернуться в корзину</Link>}</div>;
  if (!cartItems.length) return <div className="full-state"><h1>Оформлять пока нечего</h1><p>Корзина пуста.</p><Link className="button button--primary" to="/catalog">В каталог</Link></div>;

  return (
    <>
      <PageHero eyebrow="Шаг 2 из 2" title="Оформление заказа" description="Проверьте контакты и выберите удобный способ получения." />
      <main className="section"><div className="container checkout-layout">
        <form className="checkout-form" onSubmit={submit}>
          {error && <div className="form-message form-message--error">{error}</div>}
          <section className="checkout-section"><div className="checkout-section__title"><span>1</span><div><h2>Контактные данные</h2><p>Для подтверждения и уведомлений.</p></div></div><div className="form-grid"><label>Имя<input name="name" value={form.name} onChange={change} required placeholder="Ваше имя" /></label><label>Email<input name="email" type="email" value={form.email} onChange={change} required placeholder="you@example.com" /></label><label>Телефон<input name="phone" type="tel" value={form.phone} onChange={change} required placeholder="+7 999 000-00-00" /></label><label>Telegram<input name="telegram" value={form.telegram} onChange={change} placeholder="@username" /></label></div></section>
          <section className="checkout-section"><div className="checkout-section__title"><span>2</span><div><h2>Доставка</h2><p>Стоимость подтвердит менеджер.</p></div></div><div className="option-cards">{[['cdek','СДЭК','До пункта выдачи'],['post','Почта России','В любое отделение'],['pickup','Самовывоз','Санкт-Петербург']].map(([value,title,note]) => <label className={delivery === value ? 'active' : ''} key={value}><input type="radio" name="delivery" value={value} checked={delivery === value} onChange={() => setDelivery(value)} /><Icon name={value === 'pickup' ? 'location' : 'package'} /><strong>{title}</strong><span>{note}</span></label>)}</div><label className="wide-field">Город и адрес<textarea name="address" value={form.address} onChange={change} required placeholder="Город, улица, дом, квартира" /></label></section>
          <section className="checkout-section"><div className="checkout-section__title"><span>3</span><div><h2>Оплата</h2><p>После подтверждения состава заказа.</p></div></div><div className="option-cards option-cards--payment">{[['card','Банковская карта'],['sbp','СБП'],['balance','Баланс аккаунта']].map(([value,title]) => <label className={payment === value ? 'active' : ''} key={value}><input type="radio" name="payment" checked={payment === value} onChange={() => setPayment(value)} /><strong>{title}</strong></label>)}</div></section>
          <label className="consent"><input type="checkbox" required /><span>Я принимаю условия <Link to="/faq#offer">публичной оферты</Link> и подтверждаю контактные данные.</span></label>
          <button className="button button--primary button--large button--full" disabled={submitting}>{submitting ? 'Создаём заказ…' : 'Подтвердить заказ'}</button>
        </form>
        <aside className="checkout-summary"><h2>Ваш заказ</h2>{cartItems.map((item) => <div className="checkout-summary__item" key={`${item.card.id}-${item.orderType}-${item.quality}`}><div><strong>{item.card.name}</strong><span>{item.quantity} × {item.quality}</span></div><strong>{item.unitPrice ? `${(Number(item.unitPrice) * item.quantity).toLocaleString('ru-RU')} ₽` : 'Уточняется'}</strong></div>)}<div className="summary-total"><span>Итого</span><strong>{getCartTotal().toLocaleString('ru-RU')} ₽</strong></div><p><Icon name="info" size={16} /> Доставка и заказные позиции рассчитываются отдельно.</p></aside>
      </div></main>
    </>
  );
};

export default Checkout;
