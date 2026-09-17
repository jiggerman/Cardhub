import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useCart } from '../contexts/CartContext';
import PageHero from '../components/ui/PageHero';
import Icon from '../components/ui/Icon';
import cardBack from '../Magic_card_back.webp';

const typeLabels = { purchase: 'Покупка', reservation: 'Предзаказ', import: 'Под заказ' };

const Cart = () => {
  const { cartItems, updateQuantity, removeFromCart, clearCart, getCartTotal, getCartCount } = useCart();
  const navigate = useNavigate();

  return (
    <>
      <PageHero eyebrow="Ваш выбор" title="Корзина" description={cartItems.length ? `${getCartCount()} ${getCartCount() === 1 ? 'карта' : 'карт'} готовы к оформлению.` : 'Добавьте карты из каталога — они появятся здесь.'} />
      <main className="section">
        <div className="container">
          {!cartItems.length ? (
            <div className="empty-cart"><div className="empty-cart__icon"><Icon name="cart" size={40} /></div><h2>Корзина пока пуста</h2><p>Начните с поиска карты или загляните в каталог.</p><Link className="button button--primary" to="/catalog">Перейти в каталог</Link></div>
          ) : (
            <div className="cart-layout">
              <section className="cart-list">
                <div className="cart-list__head"><strong>Состав заказа</strong><button onClick={clearCart}>Очистить</button></div>
                {cartItems.map((item) => (
                  <article className="cart-row" key={`${item.card.id}-${item.quality}-${item.orderType}`}>
                    <Link to={`/cards/${item.card.id}`} state={{ card: item.card }} className="cart-row__image"><img src={item.card.imageUrlNormal || cardBack} alt={item.card.name} /></Link>
                    <div className="cart-row__main"><span className={`type-badge type-badge--${item.orderType}`}>{typeLabels[item.orderType]}</span><Link to={`/cards/${item.card.id}`} state={{ card: item.card }}><h3>{item.card.name}</h3></Link><p>{item.card.setCode} · #{item.card.collectorNumber} · {item.quality}</p></div>
                    <div className="stepper"><button onClick={() => updateQuantity(item.card.id, item.quality, item.orderType, item.quantity - 1)}><Icon name="minus" /></button><span>{item.quantity}</span><button onClick={() => updateQuantity(item.card.id, item.quality, item.orderType, item.quantity + 1)}><Icon name="plus" /></button></div>
                    <div className="cart-row__price"><strong>{item.card.minPrice ? `${(Number(item.card.minPrice) * item.quantity).toLocaleString('ru-RU')} ₽` : 'Уточняется'}</strong><button onClick={() => removeFromCart(item.card.id, item.quality, item.orderType)} aria-label="Удалить"><Icon name="trash" size={18} /></button></div>
                  </article>
                ))}
                <Link to="/catalog" className="back-link">← Продолжить покупки</Link>
              </section>
              <aside className="order-summary">
                <span className="eyebrow">Ваш заказ</span><h2>Итого</h2>
                <div className="summary-lines"><div><span>Товары</span><strong>{getCartTotal().toLocaleString('ru-RU')} ₽</strong></div><div><span>Доставка</span><strong>рассчитаем далее</strong></div></div>
                <div className="summary-total"><span>К оплате</span><strong>{getCartTotal().toLocaleString('ru-RU')} ₽</strong></div>
                <button className="button button--primary button--large button--full" onClick={() => navigate('/checkout')}>Перейти к оформлению <Icon name="arrow" /></button>
                <p><Icon name="shield" size={16} /> Финальная стоимость позиций «Под заказ» согласуется до оплаты.</p>
              </aside>
            </div>
          )}
        </div>
      </main>
    </>
  );
};

export default Cart;
