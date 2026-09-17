import React, { useContext, useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { API_BASE_URL, API_ENDPOINTS } from '../services/api';
import { AuthContext } from '../contexts/AuthContext';
import Icon from '../components/ui/Icon';

const Auth = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const { login } = useContext(AuthContext);
  const [mode, setMode] = useState(location.state?.mode || 'login');
  const [form, setForm] = useState({ username: '', email: '', password: '', confirmPassword: '' });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const isLogin = mode === 'login';

  const change = (event) => setForm({ ...form, [event.target.name]: event.target.value });
  const submit = async (event) => {
    event.preventDefault(); setError('');
    if (!isLogin && form.password !== form.confirmPassword) { setError('Пароли не совпадают'); return; }
    setLoading(true);
    try {
      const response = await fetch(`${API_BASE_URL}${isLogin ? API_ENDPOINTS.AUTH.LOGIN : API_ENDPOINTS.AUTH.REGISTER}`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(isLogin ? { email: form.email, password: form.password } : { username: form.username, email: form.email, password: form.password, password2: form.confirmPassword }),
      });
      const data = await response.json();
      if (!response.ok) throw new Error(data.error || Object.values(data).flat().join(' ') || 'Не удалось продолжить');
      const userResponse = await fetch(`${API_BASE_URL}${API_ENDPOINTS.AUTH.ME}`, { headers: { Authorization: `Bearer ${data.tokens.access}` } });
      if (!userResponse.ok) throw new Error('Не удалось загрузить профиль');
      const user = await userResponse.json();
      login(user, { access_token: data.tokens.access, refresh_token: data.tokens.refresh });
      navigate(location.state?.from || '/profile');
    } catch (err) { setError(err.message); } finally { setLoading(false); }
  };

  return (
    <main className="auth-page">
      <div className="auth-page__art"><div className="auth-art__content"><span className="eyebrow">Личный кабинет</span><h1>Ваша коллекция начинается здесь.</h1><p>Следите за заказами, сохраняйте контакты и получайте уведомления о редких картах.</p><div className="auth-benefits"><span><Icon name="check" /> История всех заказов</span><span><Icon name="check" /> Уведомления в Telegram</span><span><Icon name="check" /> Быстрое оформление</span></div></div></div>
      <div className="auth-page__form">
        <Link className="wordmark auth-wordmark" to="/">Card<span>Hub</span></Link>
        <div className="auth-panel">
          <div className="auth-tabs"><button className={isLogin ? 'active' : ''} onClick={() => { setMode('login'); setError(''); }}>Вход</button><button className={!isLogin ? 'active' : ''} onClick={() => { setMode('register'); setError(''); }}>Регистрация</button></div>
          <h2>{isLogin ? 'С возвращением' : 'Создать аккаунт'}</h2><p>{isLogin ? 'Введите данные, чтобы продолжить.' : 'Понадобится меньше минуты.'}</p>
          {error && <div className="form-message form-message--error">{error}</div>}
          <form onSubmit={submit} className="form-stack">
            {!isLogin && <label>Имя пользователя<input name="username" value={form.username} onChange={change} required autoComplete="username" placeholder="Как к вам обращаться" /></label>}
            <label>Email<input name="email" type="email" value={form.email} onChange={change} required autoComplete="email" placeholder="you@example.com" /></label>
            <label>Пароль<input name="password" type="password" value={form.password} onChange={change} required autoComplete={isLogin ? 'current-password' : 'new-password'} placeholder="Не менее 8 символов" /></label>
            {!isLogin && <label>Повторите пароль<input name="confirmPassword" type="password" value={form.confirmPassword} onChange={change} required autoComplete="new-password" placeholder="Ещё раз" /></label>}
            <button className="button button--primary button--full button--large" disabled={loading}>{loading ? 'Подождите…' : isLogin ? 'Войти' : 'Создать аккаунт'}</button>
          </form>
          <p className="auth-legal">Продолжая, вы соглашаетесь с <Link to="/faq#offer">публичной офертой</Link> и обработкой данных.</p>
        </div>
      </div>
    </main>
  );
};

export default Auth;
