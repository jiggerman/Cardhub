export const API_BASE_URL = 'http://localhost:5000';

export const API_ENDPOINTS = {
  AUTH: {
    REGISTER: '/auth/register',
    LOGIN: '/auth/login',
    PROFILE: '/auth/user_update_profile',
  },
  CARDS: {
    SEARCH: '/cards/search/',
  }
};

// Функция для создания авторизованного запроса
export const authFetch = async (url, options = {}) => {
  const token = localStorage.getItem('token');
  
  const headers = {
    'Content-Type': 'application/json',
    ...options.headers,
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const response = await fetch(`${API_BASE_URL}${url}`, {
    ...options,
    headers,
  });

  if (response.status === 401) {
    // Токен невалидный - разлогиниваем
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    window.location.href = '/auth';
  }

  return response;
};