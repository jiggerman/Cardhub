// pages/Profile.jsx
import React, { useState, useEffect } from 'react';
import {
  Container,
  Typography,
  Box,
  Paper,
  Button,
  TextField,
  Avatar,
  Alert,
  Divider,
  useMediaQuery,
  useTheme,
  CircularProgress
} from '@mui/material';
import { Telegram, CheckCircle } from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';
import { authFetch, API_ENDPOINTS } from '../services/api';

const Profile = () => {
  const { user, logout, updateUser } = useAuth();
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  
  const [userData, setUserData] = useState({
    username: '',
    email: '',
    telegram_username: '',
    telegram_verified: false
  });
  const [newTelegramUsername, setNewTelegramUsername] = useState('');
  const [saveLoading, setSaveLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  // Инициализация данных
  useEffect(() => {
    if (user) {
      setUserData({
        username: user.username || '',
        email: user.email || '',
        telegram_username: user.telegram_username || '',
        telegram_verified: user.telegram_verified || false
      });
      setNewTelegramUsername(user.telegram_username || '');
    }
  }, [user]);

  // Загружаем данные при входе
  useEffect(() => {
    const loadUserData = async () => {
      try {
        const response = await authFetch(API_ENDPOINTS.AUTH.USER || '/api/auth/user', {
          method: 'GET'
        });

        if (response.ok) {
          const data = await response.json();
          if (data.user) {
            updateUser(data.user);
            setUserData({
              username: data.user.username || '',
              email: data.user.email || '',
              telegram_username: data.user.telegram_username || '',
              telegram_verified: data.user.telegram_verified || false
            });
            setNewTelegramUsername(data.user.telegram_username || '');
          }
        }
      } catch (err) {
        console.error('Ошибка загрузки данных:', err);
      }
    };

    loadUserData();
  }, []);

  const handleConnectTelegram = async () => {
    if (!newTelegramUsername.trim()) {
      setError('Введите Telegram username');
      return;
    }

    setSaveLoading(true);
    setError('');
    setSuccess('');

    try {
      // Сохраняем Telegram
      const saveResponse = await authFetch(API_ENDPOINTS.AUTH.PROFILE_UPDATE || '/api/auth/user_update_profile', {
        method: 'POST',
        body: JSON.stringify({
          telegram_username: newTelegramUsername.trim()
        }),
      });

      if (!saveResponse.ok) {
        const errorData = await saveResponse.json();
        throw new Error(errorData.message || 'Ошибка при сохранении');
      }

      // Обновляем данные
      const updatedResponse = await authFetch(API_ENDPOINTS.AUTH.USER || '/api/auth/user', {
        method: 'GET'
      });

      if (updatedResponse.ok) {
        const data = await updatedResponse.json();
        if (data.user) {
          updateUser(data.user);
          setUserData({
            username: data.user.username || '',
            email: data.user.email || '',
            telegram_username: data.user.telegram_username || '',
            telegram_verified: data.user.telegram_verified || false
          });
          setNewTelegramUsername(data.user.telegram_username || '');
        }
      }
      
      // Открываем бота
      const botUrl = `https://t.me/CardHubStore_bot`;
      window.open(botUrl, '_blank', 'noopener,noreferrer');
      
      setSuccess('Telegram username сохранен. Перейдите в бота для подтверждения');

    } catch (err) {
      setError(err.message || 'Ошибка при сохранении');
    } finally {
      setSaveLoading(false);
    }
  };

  const handleTelegramChange = (e) => {
    const value = e.target.value.replace('@', '');
    setNewTelegramUsername(value);
  };

  const handleLogout = () => {
    logout();
  };

  if (!user) {
    return (
      <Container>
        <Typography variant="h5" align="center" sx={{ mt: 4 }}>
          Пользователь не найден
        </Typography>
      </Container>
    );
  }

  return (
    <Container maxWidth="sm" sx={{ 
      mt: isMobile ? 2 : 4, 
      mb: isMobile ? 2 : 4,
      px: isMobile ? 2 : 3 
    }}>
      <Paper elevation={isMobile ? 1 : 3} sx={{ 
        p: isMobile ? 3 : 4,
        borderRadius: isMobile ? 2 : 3
      }}>
        {/* Заголовок и кнопка выхода */}
        <Box sx={{ 
          display: 'flex', 
          flexDirection: isMobile ? 'column' : 'row',
          justifyContent: 'space-between', 
          alignItems: isMobile ? 'stretch' : 'center', 
          mb: 3,
          gap: isMobile ? 2 : 0
        }}>
          <Typography 
            variant={isMobile ? "h5" : "h4"} 
            component="h1"
            sx={{ textAlign: isMobile ? 'center' : 'left' }}
          >
            Профиль пользователя
          </Typography>
          
          <Button
            variant="outlined"
            color="error"
            onClick={handleLogout}
            fullWidth={isMobile}
            size={isMobile ? "medium" : "normal"}
          >
            Выйти
          </Button>
        </Box>

        {/* Уведомления */}
        {(error || success) && (
          <Box sx={{ mb: 3 }}>
            {error && (
              <Alert severity="error" sx={{ mb: 1 }}>
                {error}
              </Alert>
            )}
            {success && (
              <Alert severity="success">
                {success}
              </Alert>
            )}
          </Box>
        )}

        {/* Аватар и основная информация */}
        <Box sx={{ 
          display: 'flex', 
          flexDirection: 'column', 
          alignItems: 'center',
          textAlign: 'center',
          mb: 4
        }}>
          <Avatar
            sx={{ 
              width: isMobile ? 96 : 112, 
              height: isMobile ? 96 : 112, 
              mb: 2,
              fontSize: isMobile ? '2.5rem' : '3rem',
              bgcolor: 'primary.main'
            }}
          >
            {userData.username?.charAt(0).toUpperCase()}
          </Avatar>
          <Typography 
            variant="h6" 
            sx={{ 
              fontWeight: 600,
              mb: 0.5
            }}
          >
            {userData.username}
          </Typography>
          <Typography 
            variant="body2" 
            color="text.secondary"
            sx={{ 
              wordBreak: 'break-word',
              maxWidth: '100%',
            }}
          >
            {userData.email}
          </Typography>
        </Box>

        <Box component="form">
          {/* Основная информация */}
          <Box sx={{ mb: 4 }}>
            <Typography variant="subtitle1" sx={{ 
              fontWeight: 600, 
              mb: 2,
              color: 'text.primary'
            }}>
              Основная информация
            </Typography>
            
            <TextField
              fullWidth
              label="Имя пользователя"
              value={userData.username}
              margin="normal"
              disabled
              helperText="Имя пользователя нельзя изменить"
              size={isMobile ? "small" : "medium"}
            />

            <TextField
              fullWidth
              label="Email"
              type="email"
              value={userData.email}
              margin="normal"
              disabled
              helperText="Email нельзя изменить"
              size={isMobile ? "small" : "medium"}
            />
          </Box>

          <Divider sx={{ my: 3 }} />

          {/* Секция Telegram */}
          <Box sx={{ mb: 2 }}>
            <Box sx={{ 
              display: 'flex', 
              alignItems: 'center',
              gap: 1.5,
              mb: 2
            }}>
              <Telegram color="primary" />
              <Typography variant="subtitle1" sx={{ fontWeight: 600 }}>
                Telegram
              </Typography>
            </Box>

            {!userData.telegram_verified ? (
              <>
                <TextField
                  fullWidth
                  label="Telegram username"
                  value={newTelegramUsername}
                  onChange={handleTelegramChange}
                  disabled={saveLoading}
                  placeholder="username"
                  helperText="Введите ваш Telegram username (без @)"
                  size="medium"
                  sx={{ mb: 3 }}
                />
                
                <Button
                  fullWidth
                  variant="contained"
                  color="primary"
                  startIcon={<Telegram />}
                  onClick={handleConnectTelegram}
                  disabled={saveLoading || !newTelegramUsername.trim()}
                  size="large"
                >
                  {saveLoading ? (
                    <CircularProgress size={24} sx={{ color: 'white' }} />
                  ) : (
                    'Сохранить и подтвердить в Telegram'
                  )}
                </Button>
              </>
            ) : (
              <Box sx={{ mt: 2 }}>
                <TextField
                  fullWidth
                  label="Telegram username"
                  value={`@${userData.telegram_username}`}
                  disabled
                  helperText="Telegram подтвержден"
                  size="medium"
                  sx={{ mb: 3 }}
                  InputProps={{
                    readOnly: true,
                    endAdornment: (
                      <Box sx={{ display: 'flex', alignItems: 'center', color: 'success.main' }}>
                        <CheckCircle sx={{ mr: 0.5 }} />
                        <Typography variant="caption" color="success.main">
                          Подтверждено
                        </Typography>
                      </Box>
                    )
                  }}
                />
                
                <Button
                  fullWidth
                  variant="outlined"
                  color="primary"
                  startIcon={<Telegram />}
                  href="https://t.me/CardHubStore_bot"
                  target="_blank"
                  rel="noopener noreferrer"
                  size="large"
                >
                  Открыть Telegram бота
                </Button>
              </Box>
            )}
          </Box>
        </Box>
      </Paper>
    </Container>
  );
};

export default Profile;