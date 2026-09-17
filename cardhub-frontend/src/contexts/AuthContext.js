// contexts/AuthContext.js
import React, { createContext, useState, useEffect, useContext } from 'react';
import { API_BASE_URL, API_ENDPOINTS } from '../services/api';

export const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Проверяем сохраненный токен при загрузке
    const savedToken = localStorage.getItem('token');
    const savedUser = localStorage.getItem('user');
    
    if (savedToken && savedUser) {
      try {
        setToken(savedToken);
        setUser(JSON.parse(savedUser));
        fetch(`${API_BASE_URL}${API_ENDPOINTS.AUTH.ME}`, {
          headers: { Authorization: `Bearer ${savedToken}` },
        }).then(async (response) => {
          if (!response.ok) throw new Error('Session expired');
          const currentUser = await response.json();
          setUser(currentUser);
          localStorage.setItem('user', JSON.stringify(currentUser));
        }).catch(() => {
          setToken(null); setUser(null);
          localStorage.removeItem('token'); localStorage.removeItem('user'); localStorage.removeItem('refreshToken');
        }).finally(() => setLoading(false));
        return;
      } catch (error) {
        console.error('Error parsing saved user data:', error);
        localStorage.removeItem('token');
        localStorage.removeItem('user');
      }
    }
    setLoading(false);
  }, []);

  const login = (userData, tokens) => {
    setToken(tokens.access_token);
    setUser(userData);
    localStorage.setItem('token', tokens.access_token);
    if (tokens.refresh_token) localStorage.setItem('refreshToken', tokens.refresh_token);
    localStorage.setItem('user', JSON.stringify(userData));
  };

  const logout = async () => {
    const refreshToken = localStorage.getItem('refreshToken');
    if (refreshToken) {
      try {
        await fetch(`${API_BASE_URL}${API_ENDPOINTS.AUTH.LOGOUT}`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
          body: JSON.stringify({ refresh_token: refreshToken }),
        });
      } catch { /* Local logout must still complete if the API is unavailable. */ }
    }
    setToken(null);
    setUser(null);
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    localStorage.removeItem('refreshToken');
  };

  const updateUser = (updatedUserData) => {
    const updatedUser = {
      ...user,
      ...updatedUserData
    };
    setUser(updatedUser);
    localStorage.setItem('user', JSON.stringify(updatedUser));
  };

  const isAuthenticated = () => {
    return !!token && !!user;
  };

  const isAdmin = () => {
    if (!user) return false;
    return user.role === 'admin';
  };

  const value = {
    user,
    token,
    login,
    logout,
    updateUser,
    isAuthenticated,
    isAdmin,
    loading
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
