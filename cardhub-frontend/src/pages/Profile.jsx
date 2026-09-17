import React, { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { authFetch, API_ENDPOINTS } from '../services/api';
import { useAuth } from '../contexts/AuthContext';
import PageHero from '../components/ui/PageHero';
import Icon from '../components/ui/Icon';

const Profile = () => {
  const { user, updateUser, logout } = useAuth();
  const navigate = useNavigate();
  const [telegram, setTelegram] = useState(user?.telegram_username || '');
  const [message, setMessage] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    authFetch(API_ENDPOINTS.AUTH.ME).then(async (response) => { if (response.ok) { const data = await response.json(); updateUser(data); setTelegram(data.telegram_username || ''); } });
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const saveTelegram = async () => {
    setSaving(true); setMessage('');
    try {
      const response = await authFetch(API_ENDPOINTS.AUTH.ME, { method: 'PATCH', body: JSON.stringify({ telegram_username: telegram.replace('@', '').trim() }) });
      const data = await response.json();
      if (!response.ok) throw new Error(data.telegram_username?.[0] || 'Не удалось сохранить');
      updateUser(data); setMessage('Telegram сохранён. Подтвердите его через бота.');
    } catch (error) { setMessage(error.message); } finally { setSaving(false); }
  };

  const exit = () => { logout(); navigate('/'); };
  const initial = (user?.username || user?.email || 'U').slice(0, 1).toUpperCase();

  return (
    <><PageHero eyebrow="Личный кабинет" title={`Привет, ${user?.username || 'коллекционер'}`} description="Контакты, уведомления и быстрый доступ к заказам." /><main className="section"><div className="container profile-layout">
      <aside className="profile-sidebar"><div className="profile-avatar">{initial}</div><strong>{user?.username || 'Пользователь'}</strong><span>{user?.email}</span><nav><a href="#contacts" className="active">Профиль</a><Link to="/orders">Мои заказы</Link><a href="#telegram">Уведомления</a></nav><button onClick={exit}><Icon name="logout" /> Выйти</button></aside>
      <div className="profile-content">
        {message && <div className="form-message">{message}</div>}
        <section className="profile-section" id="contacts"><div><span className="eyebrow">Основное</span><h2>Контактные данные</h2><p>Имя и email берутся из аккаунта.</p></div><div className="form-grid"><label>Имя пользователя<input value={user?.username || ''} disabled /></label><label>Email<input value={user?.email || ''} disabled /></label></div></section>
        <section className="profile-section" id="telegram"><div><span className="eyebrow">Уведомления</span><h2>Telegram</h2><p>Получайте статусы заказов и сообщения о поступлении карт.</p></div><div className="telegram-connect"><div className="telegram-connect__icon"><Icon name="telegram" size={28} /></div><label>Username<input value={telegram} onChange={(event) => setTelegram(event.target.value)} placeholder="@username" /></label><button className="button button--primary" disabled={saving || !telegram.trim()} onClick={saveTelegram}>{saving ? 'Сохраняем…' : 'Сохранить'}</button></div>{user?.telegram_verified && <span className="verified"><Icon name="check" /> Telegram подтверждён</span>}</section>
        <section className="profile-section"><div><span className="eyebrow">Доставка</span><h2>Адрес по умолчанию</h2><p>Он подставится при следующем оформлении.</p></div><label className="wide-field">Адрес<textarea defaultValue={user?.shipping_address || ''} placeholder="Город, улица, дом, квартира" /></label><button className="button button--quiet" disabled>Сохранение адреса появится после обновления API</button></section>
      </div>
    </div></main></>
  );
};

export default Profile;
