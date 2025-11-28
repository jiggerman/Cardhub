import React, { useState, useContext } from 'react';
import { 
  Container, 
  Typography, 
  Box,
  TextField,
  Button,
  Paper,
  Alert,
  Link
} from '@mui/material';
import { Link as RouterLink, useLocation, useNavigate } from 'react-router-dom';
import { API_BASE_URL, API_ENDPOINTS } from '../services/api';
import { AuthContext } from '../contexts/AuthContext';

const Auth = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const { login } = useContext(AuthContext); // Используем контекст
  const mode = location.state?.mode || 'login';
  
  const [formData, setFormData] = useState({
    email: '',
    password: '',
    confirmPassword: '',
    username: ''
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const isLogin = mode === 'login';

  const handleChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };
  

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    if (!isLogin && formData.password !== formData.confirmPassword) {
      setError('Пароли не совпадают');
      setLoading(false);
      return;
    }

    try {
      const url = isLogin ? API_ENDPOINTS.AUTH.LOGIN : API_ENDPOINTS.AUTH.REGISTER;
      const payload = isLogin 
        ? { email: formData.email, password: formData.password }
        : { 
            username: formData.username, 
            email: formData.email, 
            password: formData.password 
          };

      const response = await fetch(`${API_BASE_URL}${url}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      });

      const data = await response.json();

      if (!response.ok) {
        throw new Error(data.message || data.error || 'Произошла ошибка');
      }

      if (data.access_token) {
        // Получаем данные пользователя
        const userResponse = await fetch(`${API_BASE_URL}/api/auth/user`, {
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${data.access_token}`
          }
        });
        
        if (!userResponse.ok) {
          throw new Error('Ошибка получения данных пользователя');
        }
        
        const userData = await userResponse.json();
        
        // Преобразуем данные пользователя в удобный формат
        const user = {
          id: userData.user[0],
          email: userData.user[1],
          username: userData.user[2], // Берём часть до @ из email
          role: userData.user[3],
          confirmed: userData.user[4],
          telegram_username: userData.user[7], // telegram_username
          telegram_verified: userData.user[8], // telegram_verified
          createdAt: userData.user[11], // created_at
          access_token: data.access_token,
          refresh_token: data.refresh_token
        };
        
        login(user, { 
          access_token: data.access_token,
          refresh_token: data.refresh_token 
        });
        navigate('/profile');
      } else if (!isLogin && response.status === 201) {
        // РЕГИСТРАЦИЯ - автоматически логинимся
        console.log('Регистрация успешна, выполняем автоматический вход...');
        
        const loginResponse = await fetch(`${API_BASE_URL}${API_ENDPOINTS.AUTH.LOGIN}`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            email: formData.email,
            password: formData.password
          }),
        });
        
        const loginData = await loginResponse.json();
        
        if (!loginResponse.ok) {
          throw new Error(loginData.message || 'Ошибка автоматического входа');
        }
        
        // Получаем данные пользователя после логина
        const userResponse = await fetch(`${API_BASE_URL}/api/auth/user`, {
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${loginData.access_token}`
          }
        });
        
        const userData = await userResponse.json();
        
        const user = {
          id: userData.user[0],
          email: userData.user[1],
          username: userData.user[2],
          role: userData.user[3],
          confirmed: userData.user[4],
          telegram_username: userData.user[7],
          telegram_verified: userData.user[8],
          createdAt: userData.user[11],
          access_token: loginData.access_token, 
          refresh_token: loginData.refresh_token  
        };
        
        login(user, { 
          access_token: loginData.access_token,   
          refresh_token: loginData.refresh_token   
        });
        navigate('/profile');
      }

    } catch (err) {
      setError(err.message || 'Произошла ошибка');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Container maxWidth="sm">
      <Box sx={{ mt: 8, mb: 4 }}>
        <Paper elevation={3} sx={{ p: 4 }}>
          <Typography variant="h4" component="h1" gutterBottom align="center">
            {isLogin ? 'Вход в аккаунт' : 'Регистрация'}
          </Typography>

          <Typography variant="body1" color="text.secondary" align="center" sx={{ mb: 3 }}>
            {isLogin ? 'Войдите в свой аккаунт' : 'Создайте новый аккаунт'}
          </Typography>

          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}

          <Box component="form" onSubmit={handleSubmit}>
            {!isLogin && (
              <TextField
                fullWidth
                label="Имя пользователя"
                name="username"
                value={formData.username}
                onChange={handleChange}
                margin="normal"
                required
                disabled={loading}
              />
            )}

            <TextField
              fullWidth
              label="Email"
              name="email"
              type="email"
              value={formData.email}
              onChange={handleChange}
              margin="normal"
              required
              disabled={loading}
            />

            <TextField
              fullWidth
              label="Пароль"
              name="password"
              type="password"
              value={formData.password}
              onChange={handleChange}
              margin="normal"
              required
              disabled={loading}
            />

            {!isLogin && (
              <TextField
                fullWidth
                label="Подтвердите пароль"
                name="confirmPassword"
                type="password"
                value={formData.confirmPassword}
                onChange={handleChange}
                margin="normal"
                required
                disabled={loading}
              />
            )}

            <Button
              type="submit"
              fullWidth
              variant="contained"
              size="large"
              disabled={loading}
              sx={{ mt: 3, mb: 2, py: 1.5 }}
            >
              {loading ? 'Загрузка...' : (isLogin ? 'Войти' : 'Зарегистрироваться')}
            </Button>

            <Box textAlign="center">
              <Typography variant="body2" color="text.secondary">
                {isLogin ? 'Ещё нет аккаунта? ' : 'Уже есть аккаунт? '}
                <Link 
                  component={RouterLink}
                  to="/auth"
                  state={{ mode: isLogin ? 'register' : 'login' }}
                  sx={{ cursor: 'pointer' }}
                >
                  {isLogin ? 'Зарегистрироваться' : 'Войти'}
                </Link>
              </Typography>
            </Box>
          </Box>
        </Paper>
      </Box>
    </Container>
  );
};

export default Auth;