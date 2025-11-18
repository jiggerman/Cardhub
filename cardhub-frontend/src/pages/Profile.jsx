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
  Card,
  CardContent
} from '@mui/material';
import { Edit, Save, Cancel } from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';
import { authFetch, API_ENDPOINTS } from '../services/api';

const Profile = () => {
  const { user, logout } = useAuth(); // убрали token, т.к. он не используется
  const [isEditing, setIsEditing] = useState(false);
  const [userData, setUserData] = useState({
    username: '',
    email: '',
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  useEffect(() => {
    if (user) {
      setUserData({
        username: user.username || '',
        email: user.email || '',
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
        method: 'PUT',
        body: JSON.stringify(userData),
      });

      if (!response.ok) {
        throw new Error('Ошибка при обновлении профиля');
      }

      const updatedUser = await response.json();
      setSuccess('Профиль успешно обновлен');
      setIsEditing(false);
      
      // Обновляем данные в localStorage
      localStorage.setItem('user', JSON.stringify(updatedUser.user || updatedUser));
      
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
            </Box>
          </Grid>
        </Grid>

        {/* Дополнительная информация или карточки пользователя */}
        <Box sx={{ mt: 4 }}>
          <Typography variant="h6" gutterBottom>
            Статистика
          </Typography>
          <Grid container spacing={2}>
            <Grid item xs={12} sm={6} md={3}>
              <Card>
                <CardContent>
                  <Typography color="text.secondary" gutterBottom>
                    Карточек создано
                  </Typography>
                  <Typography variant="h5">
                    0
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          </Grid>
        </Box>
      </Paper>
    </Container>
  );
};

export default Profile;