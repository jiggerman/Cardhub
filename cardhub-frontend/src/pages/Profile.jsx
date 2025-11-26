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
  Grid,
  Chip,
  Card,
  CardContent
} from '@mui/material';
import { Edit, Save, Cancel } from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';
import { authFetch, API_ENDPOINTS } from '../services/api';

const Profile = () => {
  const { user, logout, updateUser } = useAuth(); // убрали token, т.к. он не используется
  const [isEditing, setIsEditing] = useState(false);
  const [userData, setUserData] = useState({
    username: '',
    email: '',
    telegram_username: '',
    telegram_verified: false
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  useEffect(() => {
    if (user) {
      setUserData({
        username: user.username || '',
        email: user.email || '',
        telegram_username: user.telegram_username || '',
        telegram_verified: user.telegram_verified || false
      });
    }
  }, [user]);

  const handleEdit = () => {
    setIsEditing(true);
  };

  const handleCancel = () => {
    setIsEditing(false);
    // Восстанавливаем исходные данные
    setUserData({
      username: user.username || '',
      email: user.email || '',
    });
  };
  

  const handleSave = async () => {
    setLoading(true);
    setError('');
    setSuccess('');

    try {
      const response = await authFetch(API_ENDPOINTS.AUTH.PROFILE, {
        method: 'POST',
        body: JSON.stringify({
          username: userData.username,
          telegram_username: userData.telegram_username
        }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.message || 'Ошибка при обновлении профиля');
      }

      const result = await response.json();
      setSuccess(result.message || 'Профиль успешно обновлен');
      setIsEditing(false);

      // Обновляем данные через контекст
      updateUser({
        username: userData.username,
        telegram_username: userData.telegram_username
      });

    } catch (err) {
      setError(err.message || 'Произошла ошибка');
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e) => {
    setUserData({
      ...userData,
      [e.target.name]: e.target.value
    });
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
    <Container maxWidth="md" sx={{ mt: 4, mb: 4 }}>
      <Paper elevation={3} sx={{ p: 4 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
          <Typography variant="h4" component="h1">
            Профиль пользователя
          </Typography>
          
          <Box>
            {!isEditing ? (
              <Button
                startIcon={<Edit />}
                variant="outlined"
                onClick={handleEdit}
                sx={{ mr: 1 }}
              >
                Редактировать
              </Button>
            ) : (
              <>
                <Button
                  startIcon={<Save />}
                  variant="contained"
                  onClick={handleSave}
                  disabled={loading}
                  sx={{ mr: 1 }}
                >
                  Сохранить
                </Button>
                <Button
                  startIcon={<Cancel />}
                  variant="outlined"
                  onClick={handleCancel}
                  disabled={loading}
                >
                  Отмена
                </Button>
              </>
            )}
            <Button
              variant="outlined"
              color="error"
              onClick={handleLogout}
              sx={{ ml: 1 }}
            >
              Выйти
            </Button>
          </Box>
        </Box>

        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        {success && (
          <Alert severity="success" sx={{ mb: 2 }}>
            {success}
          </Alert>
        )}

        <Grid container spacing={3}>
          <Grid item xs={12} md={4}>
            <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
              <Avatar
                sx={{ width: 120, height: 120, mb: 2 }}
              >
                {user.username?.charAt(0).toUpperCase()}
              </Avatar>
              <Typography variant="h6">
                {user.username}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {user.email}
              </Typography>
            </Box>
          </Grid>

          <Grid item xs={12} md={8}>
            <Box component="form">
              <TextField
                fullWidth
                label="Имя пользователя"
                name="username"
                value={userData.username}
                onChange={handleChange}
                margin="normal"
                disabled={!isEditing || loading}
              />

              <TextField
                fullWidth
                label="Email"
                name="email"
                type="email"
                value={userData.email}
                onChange={handleChange}
                margin="normal"
                disabled={!isEditing || loading}
              />

              {/* Секция Telegram */}
              <Box sx={{ mt: 2, p: 2, border: '1px solid', borderColor: 'divider', borderRadius: 1 }}>
                <Typography variant="h6" gutterBottom>
                  Telegram
                </Typography>
                
                <TextField
                  fullWidth
                  label="Telegram username"
                  name="telegram_username"
                  value={userData.telegram_username}
                  onChange={handleChange}
                  margin="normal"
                  disabled={!isEditing || loading}
                  placeholder="username (без @)"
                  helperText="Укажите ваш Telegram username для уведомлений"
                />

                {/* Статус подтверждения */}
                {userData.telegram_username && (
                  <Box sx={{ mt: 2, display: 'flex', alignItems: 'center', gap: 2 }}>
                    <Typography variant="body2">
                      Статус: 
                      <Chip 
                        label={userData.telegram_verified ? "Подтверждён" : "Не подтверждён"} 
                        color={userData.telegram_verified ? "success" : "warning"} 
                        size="small"
                        sx={{ ml: 1 }}
                      />
                    </Typography>
                    
                    {!userData.telegram_verified && (
                      <Button
                        variant="outlined"
                        size="small"
                        href="https://t.me/your_bot" // Замените на ссылку вашего бота
                        target="_blank"
                        rel="noopener noreferrer"
                      >
                        Подтвердить Telegram
                      </Button>
                    )}
                  </Box>
                )}
              </Box>
            </Box>
          </Grid>
        </Grid>

      </Paper>
    </Container>
  );
};

export default Profile;