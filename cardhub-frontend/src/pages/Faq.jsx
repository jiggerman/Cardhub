import React, { useState } from 'react';
import PageHero from '../components/ui/PageHero';
import Icon from '../components/ui/Icon';

const questions = [
  ['Чем отличаются покупка, предзаказ и заказ?', 'Покупка — карта уже на нашем складе. Предзаказ резервирует приоритет на ближайшее поступление. Заказ означает поиск позиции у партнёра; цену и срок мы согласуем до оплаты.'],
  ['Как быстро вы собираете заказ?', 'Позиции из наличия обычно собираются за 1–2 рабочих дня. Заказные позиции проходят дополнительную сверку с партнёром.'],
  ['Можно ли объединить разные типы позиций?', 'Да. Корзина может содержать все три типа. Мы покажем отдельные сроки и не спишем оплату за заказную позицию без подтверждения.'],
  ['Как определяется состояние карты?', 'Используем стандартные градации NM, SP, MP, HP и DM. Состояние указывается у каждой конкретной позиции.'],
];

const Faq = () => {
  const [open, setOpen] = useState(0);
  return <><PageHero eyebrow="Помощь" title="Всё важное до покупки" description="Коротко о типах заказов, оплате, доставке и состоянии карт." /><main className="section"><div className="container faq-layout"><section><div className="faq-list">{questions.map(([question, answer], index) => <article className={open === index ? 'open' : ''} key={question}><button onClick={() => setOpen(open === index ? -1 : index)}><span>{question}</span><Icon name="chevronDown" /></button>{open === index && <p>{answer}</p>}</article>)}</div></section><aside className="contact-card"><span className="eyebrow">Остались вопросы?</span><h2>Напишите нам</h2><p>Поможем найти карту, уточним состояние и рассчитаем доставку.</p><a className="button button--primary button--full" href="https://t.me/CardHubStore_bot" target="_blank" rel="noreferrer"><Icon name="telegram" /> Открыть Telegram</a><a href="mailto:support@cardhub.pw">support@cardhub.pw</a></aside></div><div className="container offer-block" id="offer"><span className="eyebrow">Документы</span><h2>Публичная оферта</h2><p>Перед оплатой пользователь подтверждает условия продажи. Финальные реквизиты и полный текст документа будут опубликованы владельцем магазина до запуска платежей.</p></div></main></>;
};

export default Faq;
