import React from 'react';
import { Link } from 'react-router-dom';
import PageHero from '../components/ui/PageHero';
import Icon from '../components/ui/Icon';

const Orders = () => (
  <>
    <PageHero eyebrow="Личный кабинет" title="Мои заказы" description="Покупки, предзаказы и позиции от партнёров — в одной истории." />
    <main className="section"><div className="container orders-layout">
      <div className="orders-tabs"><button className="active">Все</button><button>Покупки</button><button>Под заказ</button><button>Предзаказы</button></div>
      <div className="orders-empty"><div className="orders-empty__graphic"><Icon name="package" size={38} /></div><h2>Заказов пока нет</h2><p>Когда вы оформите первый заказ, здесь появятся его состав, статус и этапы доставки.</p><Link to="/catalog" className="button button--primary">Найти первую карту</Link></div>
    </div></main>
  </>
);

export default Orders;
