import React from 'react';
import { BrowserRouter, Navigate, Route, Routes, useLocation } from 'react-router-dom';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { CartProvider } from './contexts/CartContext';
import Header from './components/layout/Header';
import Footer from './components/layout/Footer';
import Home from './pages/Home';
import Catalog from './pages/Catalog';
import Product from './pages/Product';
import Cart from './pages/Cart';
import Checkout from './pages/Checkout';
import Auth from './pages/Auth';
import Profile from './pages/Profile';
import Orders from './pages/Orders';
import Faq from './pages/Faq';
import './App.css';

const ProtectedRoute = ({ children }) => {
  const { isAuthenticated, loading } = useAuth();
  const location = useLocation();
  if (loading) return <div className="full-state"><span className="loader" />Проверяем аккаунт…</div>;
  return isAuthenticated() ? children : <Navigate to="/auth" state={{ from: location.pathname }} replace />;
};

const Shell = () => {
  const location = useLocation();
  const standalone = location.pathname === '/auth';
  return <div className="app-shell">{!standalone && <Header />}<Routes>
    <Route path="/" element={<Home />} />
    <Route path="/catalog" element={<Catalog />} />
    <Route path="/cards/:cardId" element={<Product />} />
    <Route path="/cart" element={<Cart />} />
    <Route path="/checkout" element={<ProtectedRoute><Checkout /></ProtectedRoute>} />
    <Route path="/auth" element={<Auth />} />
    <Route path="/profile" element={<ProtectedRoute><Profile /></ProtectedRoute>} />
    <Route path="/orders" element={<ProtectedRoute><Orders /></ProtectedRoute>} />
    <Route path="/faq" element={<Faq />} />
    <Route path="*" element={<Navigate to="/" replace />} />
  </Routes>{!standalone && <Footer />}</div>;
};

const App = () => (
  <AuthProvider>
    <CartProvider>
      <BrowserRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <Shell />
      </BrowserRouter>
    </CartProvider>
  </AuthProvider>
);

export default App;
