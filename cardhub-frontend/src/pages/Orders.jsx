import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { ordersAPI } from '../services/ordersAPI';
import PageHero from '../components/ui/PageHero';
import Icon from '../components/ui/Icon';

const typeLabels = { purchase: 'Покупка', import: 'Под заказ', reservation: 'Предзаказ' };
const statusLabels = { pending: 'Ожидает оплаты', assembly: 'Сборка', in_transit: 'В доставке', delivered: 'Доставлен', cancelled: 'Отменён', verification: 'Сверка позиций', shipping_to_spb: 'Едет в Санкт-Петербург', notified: 'Ожидает клиента', under_consideration: 'На рассмотрении' };

const Orders = () => {
  const [orders, setOrders] = useState([]);
  const [filter, setFilter] = useState('all');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => { ordersAPI.list().then(setOrders).catch((requestError) => setError(requestError.message)).finally(() => setLoading(false)); }, []);
  const visible = filter === 'all' ? orders : orders.filter((order) => order.orderType === filter);

  return <><PageHero eyebrow="Личный кабинет" title="Мои заказы" description="Покупки, предзаказы и позиции от партнёров — в одной истории." /><main className="section"><div className="container orders-layout">
    <div className="orders-tabs">{[['all','Все'],['purchase','Покупки'],['import','Под заказ'],['reservation','Предзаказы']].map(([value, label]) => <button key={value} className={filter === value ? 'active' : ''} onClick={() => setFilter(value)}>{label}</button>)}</div>
    {loading && <div className="catalog-state"><span className="loader" /><strong>Загружаем заказы…</strong></div>}
    {error && <div className="form-message form-message--error">{error}</div>}
    {!loading && !error && !visible.length && <div className="orders-empty"><div className="orders-empty__graphic"><Icon name="package" size={38} /></div><h2>Заказов пока нет</h2><p>Когда вы оформите первый заказ, здесь появятся его состав, статус и этапы доставки.</p><Link to="/catalog" className="button button--primary">Найти первую карту</Link></div>}
    <div className="orders-list">{visible.map((order) => <article className="order-card" key={order.id}><div className="order-card__head"><div><span className={`type-badge type-badge--${order.orderType}`}>{typeLabels[order.orderType]}</span><h2>Заказ #{order.id}</h2><p>{new Date(order.created_at).toLocaleString('ru-RU')}</p></div><span className={`order-status order-status--${order.status}`}>{statusLabels[order.status] || order.status}</span></div><div className="order-card__items">{order.items.map((item) => <div key={item.id}><img src={item.card.image_url_small} alt="" /><span><strong>{item.card.name}</strong><small>{item.card.set_code} · #{item.card.collection_number} · {item.quality} · {item.quantity} шт.</small></span><strong>{item.unit_price ? `${Number(item.unit_price).toLocaleString('ru-RU')} ₽` : 'Цена уточняется'}</strong></div>)}</div>{order.tracking_number && <p className="order-tracking">Трек-номер: <strong>{order.tracking_number}</strong></p>}</article>)}</div>
  </div></main></>;
};

export default Orders;
