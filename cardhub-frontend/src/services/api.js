export const API_BASE_URL = (process.env.REACT_APP_API_BASE_URL || '').replace(/\/$/, '');

export const API_ENDPOINTS = {
  AUTH: {
    REGISTER: '/api/register/',
    LOGIN: '/api/login/',
    LOGOUT: '/api/logout/',
    ME: '/api/user/me/',
  },
  CARDS: {
    SEARCH: '/api/cards/',
  },
  ORDERS: '/api/orders/',
};

export const readApiError = async (response, fallback = 'Произошла ошибка') => {
  let data;
  try { data = await response.json(); } catch { return fallback; }
  const flatten = (value) => {
    if (Array.isArray(value)) return value.map(flatten).join(' ');
    if (value && typeof value === 'object') return Object.values(value).map(flatten).join(' ');
    return String(value || '');
  };
  return data.error || data.detail || data.message || flatten(data) || fallback;
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

  if (response.status === 401 && !options.skipAuthRedirect) {
    // Токен невалидный - разлогиниваем
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    localStorage.removeItem('refreshToken');
    window.location.href = '/auth';
  }

  return response;
};
