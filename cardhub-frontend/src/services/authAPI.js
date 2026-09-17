import { API_BASE_URL, API_ENDPOINTS, readApiError } from './api';

export const authAPI = {
  async login(credentials) {
    const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.AUTH.LOGIN}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(credentials),
    });
    
    if (!response.ok) {
      throw new Error(await readApiError(response, 'Ошибка входа'));
    }
    return response.json();
  },

  async register(userData) {
    const response = await fetch(`${API_BASE_URL}${API_ENDPOINTS.AUTH.REGISTER}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(userData),
    });
    
    if (!response.ok) {
      throw new Error(await readApiError(response, 'Ошибка регистрации'));
    }
    return response.json();
  }
};
